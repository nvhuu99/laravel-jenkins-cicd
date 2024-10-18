# CI/CD with Jenkins for Laravel + MySQL Application

## Integration Branch CI/CD Pipeline

In the development stage, teams typically create multiple branches aligned with the specific issues or tasks they are working on, known as **feature branches**. Additionally, an **integration branch** consolidates the work of all team members. This integration branch must be continuously synchronized with feature branches to detect and **resolve code conflicts** early in smaller units. Moreover, automated testing ensures that the codebase remains stable throughout development.

This pipeline is designed to support that process. It continuously checks for new updates from feature branches and merges them into the integration branch. Afterward, it builds a Docker image, pushes it to the registry (DockerHub), and deploys it to the integration environment using **Kubernetes**. The system also runs unit tests using **PHPUnit**. If any issue arises (e.g., merge conflicts, test failures), the team receives an **email notification** to act promptly.

### Pipeline Steps

1. **Create a temporary branch** from the integration branch and attempt to merge changes from the feature branch.
2. **Perform the actual merge** into the integration branch if no conflicts are detected.
3. **Set up the application** by running `composer` and `npm` commands, build the application image, and push it to DockerHub.
4. **Deploy the application** to the integration environment using Kubernetes.
5. **Run unit tests** to validate the code.
6. **Notify the team via email** if any step fails (e.g., merge conflicts, test errors, deployment issues).

---

## Project Directory Structure

- [`/app`](./app): Contains configuration files used to build the Docker image for the application.
- [`/jenkins-agents`](./jenkins-agents): Stores bash scripts for the pipeline steps.
- [`/jenkins-master`](./jenkins-master): Contains bash scripts for Jenkins administration tasks.
- [`/kubernetes`](./kubernetes): Includes deployment configuration files for Kubernetes.

### Key Files
- [`jenkins-master/items/pipelines/checkin_integration_branch/Jenkinsfile`](./jenkins-master/items/pipelines/checkin_integration_branch/Jenkinsfile): Defines the pipeline configuration.
- [`dockerfile.agent`](./dockerfile.agent): Used to build the Jenkins agent Docker image.
- [`dockerfile.master`](./dockerfile.master): Used to build the Jenkins master Docker image.
- [`dockerfile.app`](./dockerfile.app): Used by the Jenkins agent to build the Laravel app image.
- [`docker-compose.yml`](./docker-compose.yml): Facilitates local testing by setting up the Jenkins master and agents quickly.

