 github-actions
 Repository for reusable workflows and composite actions.
 Support scripts for these are also stored here


Example use of composite actions:

 jobs:
   example_job:
     runs-on: ubuntu-latest
     steps:
       - name: Checkout code
         uses: actions/checkout@v2   This is a built-in action from GitHub

       - name: Use composite action from external repository
         uses: username/my-action@main   Replace 'username' with the actual username and 'my-action' with the name of the repository containing your composite action

 example of specific script:

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
         uses: username/fix-nuget-feeds@main
         with:
           NUGET_PUBLISH: 'your_publish_value'
           NUGET_SOURCE: 'your_source_value'
           NUGET_LIBRARY: 'your_library_value'
           PROGET_API_KEY: ${{ secrets.PROGET_API_KEY }}
