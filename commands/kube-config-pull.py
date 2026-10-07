#!/usr/bin/env -S uv run --script
# /// script
# dependencies = [
#   "rich",
# ]
# ///

import asyncio
import json
from pathlib import Path

from rich.progress import Progress, SpinnerColumn, TextColumn

DESTINATION_DIR = Path("/tmp/1password-dumps/kube-configs")
DESTINATION_DIR.mkdir(parents=True, exist_ok=True)

CONCURRENCY = 5


async def run_cmd(*args):
    proc = await asyncio.create_subprocess_exec(
        *args,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.DEVNULL,
    )
    stdout, _ = await proc.communicate()
    if proc.returncode != 0:
        raise RuntimeError(f"Command failed: {' '.join(args)}")
    return stdout.decode()


async def download_document(item, sem, progress, task_id):
    async with sem:
        item_id = item["id"]
        item_title = item["title"]

        safe_title = item_title.replace("/", "_")
        output_file = DESTINATION_DIR / f"{safe_title}.yaml"

        progress.update(
            task_id,
            description=f"[yellow]{item_title} (downloading)[/yellow]",
        )

        proc = await asyncio.create_subprocess_exec(
            "op",
            "document",
            "get",
            item_id,
            "--force",
            f"--out-file={output_file}",
            stdout=asyncio.subprocess.DEVNULL,
            stderr=asyncio.subprocess.DEVNULL,
        )
        await proc.wait()

        if proc.returncode == 0:
            progress.update(
                task_id,
                description=f"[green]{item_title} (done)[/green]",
                completed=1,
                total=1,
                finished=True,
                refresh=True,
            )
        else:
            progress.update(
                task_id,
                description=f"[red]{item_title} (failed)[/red]",
                completed=1,
                total=1,
                finished=True,
                refresh=True,
            )


async def main():
    output = await run_cmd(
        "op",
        "item",
        "list",
        "--categories",
        "Document",
        "--tags",
        "k8s/kubeconfig",
        "--format=json",
    )

    items = json.loads(output)
    sem = asyncio.Semaphore(CONCURRENCY)

    progress = Progress(
        SpinnerColumn(finished_text="[green]✔[/green]"),
        TextColumn("{task.description}"),
    )

    with progress:
        tasks = []

        for item in items:
            task_id = progress.add_task(
                f"[grey]{item['title']} (queued)[/grey]",
                total=None,
            )
            tasks.append(
                asyncio.create_task(
                    download_document(item, sem, progress, task_id)
                )
            )

        await asyncio.gather(*tasks)


if __name__ == "__main__":
    asyncio.run(main())
