# geyser-app

There's little of significance within this repository. The traditional interactive shiny app showcases the ubiquitous Old Faithful geyser eruption data. The only thing of interest might be the `.github/workflows/deploy.yml` and `Dockerfile` files. These were used to containerize the code and push it to a Digital Ocean droplet. Setting up a virtual private server (VPS) was mind-numbingly painful even with the assistance of AI.

## Workflow

This project uses a CI/CD (Continuous Integration/Continuous Deployment) pipeline to automatically deploy changes. When code is pushed to the `main` branch, the following automated sequence occurs:

### 1. Push to GitHub Triggers Workflow

A `git push` to the `main` branch automatically starts the build process using GitHub Actions.

#### How to Verify:

1.  Go to your GitHub repository: [https://github.com/RobWiederstein/geyser](https://github.com/RobWiederstein/geyser)
2.  Click on the **"Actions"** tab near the top of the page.
3.  You will see a list of workflow runs. The top one should correspond to your most recent commit.
    * A **yellow spinning icon** means the workflow is currently in progress.
    * A **green checkmark** ✅ means the workflow completed successfully.
    * A **red X** ❌ means the workflow failed. You can click on it to see the error logs.

### 2. Workflow Pushes Container to Docker Hub Registry

Once the GitHub Action completes successfully, its final step is to push the newly built Docker image to Docker Hub.

#### How to Verify:

1.  Log in to Docker Hub and navigate to your repository: [https://hub.docker.com/r/robwiederstein/geyser/tags](https://hub.docker.com/r/robwiederstein/geyser/tags)
2.  Look at the tags list. You should see that the **`:latest`** tag has a **"Last pushed"** timestamp of "a few minutes ago."
3.  This confirms that the new version of your image has been successfully published and is ready for deployment.

### 3. Watchtower Updates Image on Digital Ocean Droplet

A service called **Watchtower** is running as a container on the `cobalt-ember` server. By default, it checks Docker Hub every 5 minutes for new versions of your running images.

#### How to Verify:

There are two ways to verify this final step: watching it happen live or confirming the result after the fact.

**A) Watching it Happen (Live):**

1.  SSH into your `cobalt-ember` server.
2.  Run the following command to stream the Watchtower logs:
    ```bash
    docker logs -f watchtower
    ```
3.  Be patient. Within 5 minutes of the GitHub Action finishing, you will see new log lines appear, confirming the update:
    ```
    INFO: Found new image for /geyser
    INFO: Stopping /geyser...
    INFO: Creating /geyser...
    ```

**B) Confirming the Result (After the Fact):**

1.  **The Website (The True Test):** This is the ultimate proof. Go to your app's URL and perform a "hard refresh" (**Cmd+Shift+R** on Mac or **Ctrl+Shift+R** on Windows). You should see the code change you pushed.

2.  **The Server (Technical Proof):** SSH into your server and run `docker ps`.
    ```bash
    docker ps
    ```
    Look at the `STATUS` column for your `geyser` container. It should say something like **"Up about a minute"** instead of "Up 2 days," proving it was recently restarted with the new image.

---

### Final Result

Ultimately, any changes successfully pushed through this pipeline will become visible on the live application, usually within 5-10 minutes of the `git push`.

**Live App URL:** [https://apps.robwiederstein.org/geyser](https://apps.robwiederstein.org/geyser)
