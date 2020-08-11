
# Curate Rake Tasks Tutorial
# Prerequisites
## Certain Rake Tasks: SSH
Before some rake task commands, you must:
1. Login to `tki`: 
    You must be able to sign into your tki from your terminal. To learn more on how to setup, please click [here](https://wiki.service.emory.edu/pages/viewpage.action?spaceKey=DLPP&title=Install+TKI+Client+and+Connect+to+DLP+EC2s) (Emory log-in required).
2. SSH into your desired Curate environment. To do so, from the same terminal window/tab you ran `tki`, run one of the following commands: 
    - Test Environment: `ssh-ec2-priv curate-test.library.emory.edu`
    - Arch Environment: `ssh-ec2-priv curate-arch.library.emory.edu`
    - Production Environment: `ssh-ec2-priv curate.library.emory.edu`
3. `cd /opt/dlp-curate/current/`
4. You are now in the main folder of that environment's Rails application. Rake commands can be performed here.
## Certain Rake Tasks: SFTP
Some Rake Tasks require file(s) to be uploaded to your chosen environment. This requires you to sign into the SFTP interface:
1. From your terminal, within your desired folder, login to `tki`. Need help with this? See [above](#prerequisites) link.
2. Choose your environment below and run the associated command:
    - Test Environment: `sftp-ec2-priv curate-test.library.emory.edu`
    - Arch Environment:`sftp-ec2-priv curate-arch.library.emory.edu`
    - Production Environment: `sftp-ec2-priv curate.library.emory.edu`
# Available Rake Tasks
## Books Preprocessor
- To avoid tying up server resources, perform this rake task on local environment.
- This procedure combines two documents with different formats into a CSV that the Curate application can ingest.
- It requires a CSV and a XML file to run correctly. 
- There are two arguments that are required for this:
    1. A CSV file path (`csv`) provided by the ticket creator.
    2. A MARCXml file path (`xml`) also provided by the same person.
- There are also three more arguments provided by the ticket maker that alter the preprocessor's logic and are assigned defaults:
    1. `repl`(replacement_path): a string found in the ticket.
    2. `map`(workflow): options are `:limb` or `:kirtas`. Ticket will state which.
    3. `base`(start page): an integer also found in the request ticket.
- The task produces a CSV file that must be delivered to the admin/manager shown on the ZenHub issue.
### Steps
1. Place the CSV and XML files into the same folder inside of `dlp-curate` (within `tmp` is recommended).
2. Change directories in terminal to the Curate root folder, ensure that the branch is `main`, and that the code is up to date (`git pull`).
3. Build the command using this template:
    - `bundle exec rails curate:books csv="<path to csv file on local machine>" xml="<path to xml file on local machine>" repl="<replacement path from ticket>" map=<symbolized workflow from ticket> base=<start page integer from ticket>`
    - For example: `bundle exec rails curate:books csv="tmp/i_am_a.csv" xml="tmp/i_am_a.xml" repl="Yellowbacks" map=:kirtas base=5`
4. Run the command. The newly created CSV will be in the same folder that the other two files were placed and will have "-merged" added to the end of the original CSV file name. 
5. Pass the new file to the ticket creator.
## Collection Files Ingested Count
- This task counts the number of Works, FileSets, and Files ingested for Collections.
- It does not requires a CSV file to run correctly. 
- There is one optional argument (`collections`) that accepts a string of ids separated by a space. 
- The task produces a JSON file containing an array of (a) hash(es), each containing the needed Collection numbers.
### Steps
1. Login to the needed SSH environment (see [Prerequisites](#prerequisites)).
2. This procedure has two ways it can function:
    1. For a file with all Collections' hashes included, run:
        - `RAILS_ENV=production bundle exec rails curate:collection_files_ingested:process`
    2. To return a file that focuses on one or more Collection(s):
        - `RAILS_ENV=production bundle exec rails curate:collection_files_ingested:process collections="<first collection id> <second collection id"`
3. Watch for any errors after performing the command. If errors are detected, review the steps above.
4. Pull the JSON file down from the server, when the Job is finished (check Sidekiq), by:
    1. SFTPing into the right environment ([Prerequisites](#prerequisites) above), 
    2. Change directory to `/config/emory/`,
    3. `ls` to see if the file is there (the name of the file will be `collection-counts-for-<todays date/time in the format YearMonthDateTHourMinutes>.json`),
    4. and running: `get /opt/dlp-curate/current/config/emory/<name of file found in the previous ls>`.
5. The file should download into the folder you started the SFTP from. Pass the file along to the ticket creator.
## Create Work Manifests
- This procedure creates IIIF manifests for Work objects.
- It does not require a CSV file to run correctly. 
- The task can be operated two different ways, though:
    1. Ran without an argument assigned, every CurateGenericWork object will be checked to see if it has been changed since the object's manifest was created. If so, a newly created manifest will replace the old one. If the `date_modified` attribute of the object matches the date the manifest was created, a new manifest will not be created.
    2. Processed with an `id` string in the `work` argument, the procedure only focuses on that listed object and creates just its manifest.
### Steps For Creating Manifests For All Works
1. Perform the [Prerequisites](#prerequisites) for the needed SSH environment.
2. When creating new manifests for all of the site's Works, we need to delete all of the manifests that currently exist in the application:
    - First, run `rm /opt/uploads/dlp-curate/iiif_manifest_cache/*`. 
    - Then, `cd /opt/uploads/dlp-curate/iiif_manifest_cache/`
    - And finally, `ls -1 | wc -l`. This will return a count of files remaining in the folder. It should return zero. If it doesn't, repeat the above `rm` and `ls` commands until the count is zero.
3. Return to Rails root with `cd /opt/dlp-curate/current/`.
4. Paste `RAILS_ENV=production bundle exec rails curate:works:create_manifest` and press enter.
5. Monitor the output of the command for errors. Review the steps above if errors show.
### Steps For Creating Manifests For One Work
1. Perform the [Prerequisites](#prerequisites) for the needed SSH environment.
2. Before running the command, be aware we are passing a string of the Work `:id` to the rake task argument of `work`. Not declaring this key/value pair will kick off the steps to create manifests for all Works.
3. Use the command `RAILS_ENV=production bundle exec rails curate:works:create_manifest work="<put id string here>"` .
4. Check for errors. Review the steps above if errors show.
## FileSet CleanUp
- This task checks all FileSets' thumbnail paths, corrects any that are errant, and reindexes those that `mime_type`s are missing.
- It does not require a CSV file to run correctly. 
- No additional arguments are needed or accepted.
- It will produce a CSV file that will need to be passed along to the person requesting the process.
### Steps
1. Sign into and prepare the SSH environment the ticket references (see [Prerequisites](#prerequisites)).
2. From the Rails root folder, run the command below:
    - `RAILS_ENV=production bundle exec rails curate:file_sets:file_sets_cleanup`
3. Watch for any errors after performing the command. If errors are detected, review the steps above.
4. After this task completes (check Sidekiq to verify it is done), it will place a new CSV named `index_file_set_results.csv` into the following folder: `config/emory`. To retrieve it, log into the associated SFTP environment and perform:
    - `get /opt/dlp-curate/current/config/emory/index_file_set_results.csv`
    - This will download the file to your local computer in the same folder from where you signed into SFTP. For a reminder, it will be the folder you return to when `exit`ing.
## Fixity Check
- This rake task initiates [Fixity Checks](https://en.wikipedia.org/wiki/File_fixity) on every FileSet in the Curate application.
- It does not require a CSV file to run correctly. 
- This task does not accept arguments. 
- Once the Job has begun successfully, there is nothing to return to the ticket creator.
### Steps
1. Login to the needed SSH environment (see [Prerequisites](#prerequisites)).
2. Run: `RAILS_ENV=production bundle exec rails curate:file_sets:fixity_check`.
3. Watch for any errors after performing the command. If errors are detected, review the steps above.
4. Notify the ticket creator the time that the Fixity Check Job has begun.
## Langmuir Preprocessor
- To avoid tying up server resources, perform this rake task on local environment.
- This procedure uses one provided CSV to generate a properly formatted CSV file that the Curate application can ingest.
- It requires a CSV file to run correctly. 
- There is one argument that is required for this:
    - A CSV file path (`csv`) provided by the ticket creator.
- The task produces a CSV file that must be delivered to the admin/manager shown on the ZenHub issue.
### Steps
1. Place the CSV file into a folder inside of `dlp-curate` (within `tmp` is recommended).
2. Change directories in terminal to the Curate root folder, ensure that the branch is `main`, and that the code is up to date (`git pull`).
3. Build the command using this template:
    - `bundle exec rails curate:langmuir csv="<path to csv file on local machine>"`
    - For example: `bundle exec rails curate:langmuir csv="tmp/i_am_a.csv"`
4. Run the command. The newly created CSV will be placed in the same folder and will have "-processed" added to the name. 
5. Pass the processed file to the ticket creator.
## Load Preservation Workflow Metadata
- This procedure uploads metadata pulled from a provided CSV file.
- The CSV must be placed in the appropriate folder and be named correctly for the task to work.
- No additional arguments are needed or accepted.
### Steps
1. Sign into SSH environment needed (see [Prerequisites](#prerequisites)).
2. The CSV file from the ticket must be placed in `config/preservation_workflow_metadata/` and named `preservation_workflows.csv`. The `preservation_workflow_metadata` folder may not be created yet, so please `cd` into the `config` folder and `ls` it's contents. If `preservation_workflow_metadata` isn't there, run: `mkdir preservation_workflow_metadata`.
3. Once verifying the  `preservation_workflow_metadata` folder, log out of SSH, into the corresponding SFTP server and perform:
    - `put /path/to/preservation_workflows_file/on/your/computer.csv /opt/dlp-curate/current/config/reindex/preservation_workflows.csv`
4. Sign out of this SFTP environment (`exit`) and into the SSH side (for help, see [Prerequisites](#prerequisites)).
6. In the Rails root folder, run the command below:
    - `RAILS_ENV=production bundle exec rails curate:works:import_preservation_workflows`
7. See if any errors arise after sending that command in the terminal. If errors are detected, review the steps above.
## Reindex Objects
- This task updates the field values for the SolrDocument associated with the Fedora object.
- It requires a CSV file specifically named `reindex_objects.csv` to run correctly. This file is typically provided by Curate's administrators or managers in the ticket requesting this process to be run. If the file is not specifically named this way when placed into the correct folder, the process will produce errors. 
- No additional arguments are needed or accepted.
### Steps
1. Sign into SSH environment required (see [Prerequisites](#prerequisites)).
2. The CSV file must be placed in `config/reindex/`. The `reindex` folder is most likely not created yet, so please `cd` into the `config` folder and `ls` it's contents. If `reindex` isn't there, run: `mkdir reindex`.
3. Once the `reindex` folder exists, you can now log into the corresponding SFTP environment and perform:
    - `put /path/to/reindex_objects_file/on/your/computer.csv /opt/dlp-curate/current/config/reindex/reindex_objects.csv`
4. Sign out of this SFTP environment (`exit`) and log into and prepare the SSH side.
6. Once in the Rails root folder, run the command below:
    - `RAILS_ENV=production bundle exec rails curate:objects:reindex`
7. Check for any errors that arise after firing that command in the terminal. If errors are detected, review the steps above.
## S3 Binaries Check
- This rake task checks for the existence of a single or all binary(ies) inside of a specific AWS S3 Bucket by verifying their `sha1` values.
- It does not requires a CSV file to run correctly. 
- It does, however, have one argument that is required (`bucket`) and one that focuses the task on just one FileSet (`file_set`) that isn't required. 
- And it produces a CSV file listing all of the FileSets without a binary in the S3 Bucket.
### Steps
1. This process may involve some research before performing. If the ticket submitter hasn't provided the name of the S3 Bucket, reach out to them (Slack works). 
2. With the Bucket name in hand, double check the name against the actual S3 Buckets. To do so:
    1. Go to [aws.emory.edu](http://aws.emory.edu/)
    2. Click on `AWS console`
    3. Login with Open Emory details.
    4. Choose `S3`
    5. Compare the given name to the list and choose the best match.
3. Follow the procedures in the [Prerequisites](#prerequisites) above to prepare the right SSH environment.
4. This task has two ways it can function:
    1. For checking all FileSets' binaries, run:
        - `RAILS_ENV=production bundle exec rails curate:file_sets:check_binaries bucket="<bucket name verified in step 2>"`
    2. To check one specific FileSet:
        - `RAILS_ENV=production bundle exec rails curate:file_sets:check_binaries bucket="<bucket name verified in step 2>" file_set="<FileSet object id listed in ticket>"`
5. Watch for any errors after performing the command. If errors are detected, review the steps above.
6. Fetch the produced CSV file when this Job is done (check Sidekiq) by:
    1. SFTPing into the right environment and
    2. Running the command: `get /opt/dlp-curate/current/config/emory/check_binaries_results.csv`
    3. The file should download into the folder you started the SFTP from.
# After Rake Task Performed
Every processed rake task starts a background job. This job can be monitored at the Sidekiq site for the environment chosen.
- Test Environment's Sidekiq: [https://curate-test.library.emory.edu/sidekiq/busy](https://curate-test.library.emory.edu/sidekiq/busy)
- Arch's: [https://curate-arch.library.emory.edu/sidekiq/busy](https://curate-arch.library.emory.edu/sidekiq/busy)
- Production's: [https://curate.library.emory.edu/sidekiq/busy](https://curate.library.emory.edu/sidekiq/busy)