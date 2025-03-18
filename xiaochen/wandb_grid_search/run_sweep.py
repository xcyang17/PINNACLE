import wandb
import subprocess
import time
import re

# 1) Your sweep config
sweep_config = {
    "method": "grid",
    "parameters": {
        "feat_mat": {
            "values": [1024, 2048]
        }
        # Possibly more hyperparams
    }
}
sweep_id = wandb.sweep(sweep_config, project="pinnacle_sweep")

def poll_until_done(job_name):
    """Poll Slurm's queue until no jobs match 'job_name'."""
    while True:
        # squeue -n <job_name> returns lines if that job is still running
        out = subprocess.check_output(["squeue", "-n", job_name]).decode()
        lines = out.strip().split("\n")
        if len(lines) <= 1:
            # means no lines besides the header => no job
            break
        time.sleep(60)  # wait a minute, then check again
    print(f"Job {job_name} is done or not found in queue.")

def sweep_wrapper():
    wandb.init()
    feat_mat = wandb.config.feat_mat
    # If you have multiple hyperparams, read them as well

    # We'll use a "run name" that encodes this combo, e.g.
    run_name = f"feat{feat_mat}_run{wandb.run.id}"

    # Submit the chunk script as a single Slurm job
    # which will re-submit itself as needed
    sbatch_cmd = [
        "sbatch",
        "-N", "1",
        "--gres=gpu:2",
        "--job-name", run_name,
        "--mem", "30g",
        "-t", "4:00:00",
        "-A", "standby",
        "chunk_train.sh",
        str(feat_mat),
        "250",        # total epochs
        run_name
    ]
    print("Submitting:", " ".join(sbatch_cmd))
    output = subprocess.check_output(sbatch_cmd).decode()
    print("sbatch output:", output)

    # Extract the job ID from the sbatch output if needed:
    m = re.search(r"Submitted batch job (\d+)", output)
    if not m:
        print("WARNING: Couldn't parse job ID from sbatch output!")
        job_id = None
    else:
        job_id = m.group(1)
        print("Launched job ID:", job_id)

    # Now we poll for that job name to disappear from the queue
    # This ensures the run is fully done (including its re-submissions).
    poll_until_done(run_name)

    # Once done, we can do additional postprocessing if needed
    print(f"Run for feat_mat={feat_mat} is complete.")

# 2) Launch the agent
if __name__ == "__main__":
    wandb.agent(sweep_id, function=sweep_wrapper)
