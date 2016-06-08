Amazon s3 console!
===================


Hey! I'm your first Markdown document in **StackEdit**[^stackedit]. Don't delete me, I'm very helpful! I can be recovered anyway in the **Utils** tab of the <i class="icon-cog"></i> **Settings** dialog.

----------


Credentials
-------------

Default credentials are loaded automatically from the following locations:

> - **ENV['AWS_ACCESS_KEY_ID']** and **ENV['AWS_SECRET_ACCESS_KEY']**

> e.g:
> export AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxx+XocDzDU (on Linux / OSX ...)
> set AWS_SECRET_ACCESS_KEY=xxxxxxxxxxxxxxx+XocDzDU (on Windows)

> - **Aws.config[:credentials]**
> - The shared credentials ini file at ** ~/.aws/credentials**
##### Credentials format:
>[default]
aws_access_key_id = ACCESS_KEY
aws_secret_access_key = SECRET_KEY
aws_session_token = TOKEN



Region
----------

You can configure a default region in the following locations:

> - ENV['AWS_REGION']
> - Aws.config[:region]document

----------

Usage
-------------------

>as3 [operation] bucket_name [file_name] [options]

>**Where:**
>  **operation:**
             - list     - list all buckets
             - create   - create a new bucket
             - delete   - delete a bucket
             - upload   - upload file to a bucket
             - items    - list bucket items

  >**bucket_name** is the bucket name ... :p

>  **file_name** - file to upload,
              required when operation is 'upload'

> **Options:**
> ***-s NAME, --size NAME***
>  "specify the file format size, e.g. KB MB GB..."

> ***--group***
>  "group by storage type, e.g. STANDARD,STANDARD_IA,REDUCED_REDUNDANCY"

>  ***-a, --all***
>  "output additionnal information"

>  ***-r, --region***
>  "group buckets by region"

>  ***-f REGEXP, --filter REGEXP***
>  "filter buckets by REGEXP"





