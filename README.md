# GitHub Actions

Repository for reusable workflows and composite actions. Support scripts for these are also stored here.

## Example use of composite actions:

```yaml
jobs:
  example_job:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v2 # This is a built-in action from GitHub

      - name: Use composite action from external repository
        uses: username/my-action@main # Replace 'username' with the actual username and 'my-action' with the name of the repository containing your composite action
```
## Example of specific script:

```yaml
 name: Example Workflow

 on:
   push:
     branches:
       - main

 jobs:
   example_job:
     runs-on: ubuntu-latest
     steps:
       - name: Checkout code
         uses: actions/checkout@v2

       - name: Fix NuGet Feeds
         uses: cogstate-dev/github-actions/.github/Composite-Actions/Fix-Nuget-Feeds@v1.0.0
         with:
            NUGET_PUBLISH: ${{ env.NUGET_PUBLISH }}
            NUGET_SOURCE: ${{ env.NUGET_SOURCE }}
            NUGET_LIBRARY: ${{ env.NUGET_LIBRARY }}
            PROGET_API_KEY: ${{ secrets.PROGET_API_KEY }}
```
