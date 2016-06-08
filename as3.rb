require 'aws-sdk'
require 'filesize'
require 'optparse'

options = {
    load_paths: [],
    require: [],
    execute: [],
}
NO_SUCH_BUCKET = "The bucket '%s' does not exist!"

USAGE = <<DOC

Usage: as3 [operation] bucket_name [file_name] [options]

Where:
  operation:
              list     - list all buckets
              create   - create a new bucket
              upload   - upload file to a bucket
              items    - list bucket items

  bucket_name is the bucket name ... :p

  file_name - file to upload,
              required when operation is 'upload'

Options:
-s NAME,--size NAME, "specify the file format size, e.g. KB MB GB..."
--group, "group by storage type, e.g. STANDARD,STANDARD_IA,REDUCED_REDUNDANCY"
-a, –all, “output additionnal information”
-r, –region, “group buckets by region”
-f REGEXP, –filter REGEXP, “filter buckets by REGEXP”
DOC

OptionParser.new do |opts|

  opts.banner = "Usage: as3 operation] bucket_name [file_name] [options]"
  opts.separator ""
  opts.separator "Where:
  operation:
              list     - list all buckets
              create   - create a new bucket
              upload   - upload file to a bucket
              items    - list bucket items

  bucket_name is the bucket name ... :p

  file_name - file to upload,
              required when operation is 'upload'"

  opts.separator ""
  opts.separator "Specific options:"

# Ability to get the size results in bytes, KB, MB, ...
  opts.on("-s NAME", "--size NAME", "specify the file format size, e.g. KB MB GB...") do |value|
    options[:size] = value
  end

# Organize the information by storage type (Standard, IA, RR)
  opts.on("-g", "--group", "group by storage type, e.g. STANDARD,STANDARD_IA,REDUCED_REDUNDANCY") do |value|
    options[:group] = value
  end

# Organize the information by storage type (Standard, IA, RR)
  opts.on("-a", "--all", "output all informations") do |value|
    options[:all] = value
  end
# Ability to group information by regions
  opts.on("-r", "--region", "group by region,") do |value|
    options[:region] = value
  end

# Filter the result in a list of buckets
  opts.on("-f", "--filter REGEX", "filter the result,") do |value|
    options[:filter] = value
  end
# Print as3 usage
  opts.on_tail("-h", "--help") do
    puts opts
    exit
  end

end.parse!

# Set the name of the bucket on which the operations are performed.
# This argument is required.
bucket_name = nil
region = 'us-east-1'
if ARGV.length > 0
  operation = ARGV[0]
else
  puts USAGE
  exit 1
end

# The bucket name to perform an operation
bucket_name = ARGV[1] if (ARGV.length > 1)

# The file name to use with 'upload'
file = nil
file = ARGV[2] if (ARGV.length > 2)

# Get an Amazon S3 resource
# Don't forget to change your_region to the appropriate region
s3 = Aws::S3::Resource.new(region: region)

# Get the bucket by name
bucket = s3.bucket(bucket_name)


case operation
  # Bucket name
  # Creation date (of the bucket)
  # Number of files
  # Total size of files
  # Last modified date (most recent file of a bucket)
  # Group by region
  when 'list'
    $stderr.reopen('/dev/null', 'w')

    puts "Bucket name \t\t| \t\t Creation date \t\t| \t\t Number of files \t\t| \t\t Total size of files \t\t| \t\t Last modified"
    puts '==============================================================================================================================================================================================='
    # Group by region
    if options[:region]
      bucket_region = []
      if options[:filter]
        filter = options[:filter]
        buckets = s3.buckets.select { |bucket| bucket.name =~ /#{filter}/ }
      else
        buckets = s3.buckets
      end
      buckets.each do |bucket|
        if s3.client.get_bucket_location(bucket: bucket.name).location_constraint.empty?
          result = Hash["region" => region, "bucket" => bucket]
          bucket_region.push(result)
        else
          region_bucket = s3.client.get_bucket_location(bucket: bucket.name).location_constraint
          result = Hash["region" => region_bucket, "bucket" => bucket]
          bucket_region.push(result)
        end
      end


      group_by_region = bucket_region.group_by { |key| key['region'] }
      group_by_region.each do |region, object|
        puts "=================  Region: #{region}  ================="
        object.each do |obj|
          bucket = obj['bucket']
          file_size = 0
          last_modified = []

          if bucket.objects.count > 0
            bucket.objects.each do |file|
              file_size += file.size
              # Let's put it on an array and make a max to show the last updated file date on a bucket
              last_modified.push(file.last_modified)
            end
          end
          if options[:size]
            format = options[:size]
            file_size = Filesize.from("#{file_size} B").to_s(unit = "#{format}")
            puts "#{bucket.name} \t\t\t\t   | \t\t #{bucket.creation_date}  \t\t| \t\t  #{bucket.objects.count} \t\t| \t\t #{file_size}  \t\t| \t\t #{last_modified.max} "
          else
            file_size = Filesize.from("#{file_size} B").pretty
            puts "#{bucket.name} \t\t\t\t   | \t\t #{bucket.creation_date}  \t\t| \t\t  #{bucket.objects.count} \t\t| \t\t #{file_size} \t\t| \t\t #{last_modified.max} "
          end
        end
      end

    else
      if options[:filter]
        filter = options[:filter]
        buckets = s3.buckets.select { |bucket| bucket.name =~ /#{filter}/ }
      else
        buckets = s3.buckets
      end
      buckets.each do |bucket|

        file_size = 0
        last_modified = []
        if bucket.objects.count > 0
          bucket.objects.each do |file|
            file_size += file.size
            # Let's put it on an array and make a max to show the last updated file date on a bucket
            last_modified.push(file.last_modified)
          end
        end


        if options[:size]
          if options[:all]
            format = options[:size]
            file_size = Filesize.from("#{file_size} B").to_s(unit = "#{format}")
            puts "#{bucket.name} \t\t\t\t   | \t\t #{bucket.creation_date}  \t\t| \t\t  #{bucket.objects.count} \t\t| \t\t #{file_size}  \t\t| \t\t #{last_modified.max}  \t\t| \t\t  acl: #{bucket.acl}  \t\t| \t\t  cors: #{bucket.cors}  \t\t| \t\t lifecycle  #{bucket.lifecycle}   \t\t| \t\t tagging: #{bucket.tagging}  \t\t| \t\t versioning  #{bucket.versioning}  \t\t| \t\t  website: #{bucket.website}  \t\t| \t\t  url: #{bucket.url}"
          else
            format = options[:size]
            file_size = Filesize.from("#{file_size} B").to_s(unit = "#{format}")
            puts "#{bucket.name} \t\t| \t\t #{bucket.creation_date}  \t\t| \t\t  #{bucket.objects.count} \t\t| \t\t #{file_size}  \t\t| \t\t #{last_modified.max} "
          end
        else
          if options[:all]
            format = options[:size]
            file_size = Filesize.from("#{file_size} B").to_s(unit = "#{format}")
            puts "#{bucket.name} \t\t\t\t   | \t\t #{bucket.creation_date}  \t\t| \t\t  #{bucket.objects.count} \t\t| \t\t #{file_size}  \t\t| \t\t #{last_modified.max}  \t\t| \t\t   acl: #{bucket.acl}  \t\t| \t\t  cors: #{bucket.cors}  \t\t| \t\t   lifecycle: #{bucket.lifecycle}   \t\t| \t\t tagging: #{bucket.tagging}  \t\t| \t\t versioning:  #{bucket.versioning}  \t\t| \t\t website:  #{bucket.website}  \t\t| \t\t  url: #{bucket.url}"
          else
            file_size = Filesize.from("#{file_size} B").pretty
            puts "#{bucket.name} \t\t| \t\t #{bucket.creation_date}  \t\t| \t\t  #{bucket.objects.count} \t\t| \t\t #{file_size} \t\t| \t\t #{last_modified.max} "
          end
        end
      end
    end

  when 'create'
    # create a new bucket if it doesn't already exist
    if bucket.exists?
      puts "The bucket '%s' already exists!" % bucket_name
    else
      s3.create_bucket({:bucket => "#{bucket_name}"})
      puts "Created new S3 bucket: %s" % bucket_name
    end

  when 'upload'
    if file == nil
      puts "You must enter the name of the file to upload to S3!"
      exit
    end

    if bucket.exists?
      name = File.basename file

      # Check if file is already in bucket
      if bucket.object(name).exists?
        puts "#{name} already exists in the bucket"
      else
        obj = s3.bucket(bucket_name).object(name)
        obj.upload_file(file)
        puts "Uploaded '%s' to S3!" % name
      end
    else
      NO_SUCH_BUCKET % bucket_name
    end

  when 'items'
    if bucket.exists?
      # enumerate the bucket contents and object etags
      puts "Contents of '%s':" % bucket_name

      if options[:group]
        puts "File name \t\t| \t\t Size \t\t| \t\t Last modified"
        puts '==============================================================================================================================================================================================='

        # Group by storage type
        group_by_storage = bucket.objects.group_by { |key| key.storage_class }
        group_by_storage.each do |storage, object|
          puts "  Storage type: #{storage}"
          object.each do |obj|
            if options[:size]
              format = options[:size]
              file_size = Filesize.from("#{obj.size} B").to_s(unit = "#{format}")
              puts "  #{obj.key.ljust(20)}  \t\t| \t\t #{file_size}  \t\t| \t\t #{obj.last_modified}"
            else
              file_size = Filesize.from("#{obj.size} B").pretty
              puts "  #{obj.key.ljust(20)} | \t\t   \t\t #{file_size}  \t\t| \t\t #{obj.last_modified}"
            end
          end
        end
      else
        puts "File name \t| \t\t Storage type \t\t| \t\t Size \t\t| \t\t Last modified"
        puts '==============================================================================================================================================================================================='
        bucket.objects.each do |obj|
          if options[:size]
            format = options[:size]
            file_size = Filesize.from("#{obj.size} B").to_s(unit = "#{format}")
            puts "  #{obj.key.ljust(20)} | \t\t   #{obj.storage_class.ljust(20)} \t\t| \t\t #{file_size}  \t\t| \t\t #{obj.last_modified}"
          else
            file_size = Filesize.from("#{obj.size} B").pretty
            puts "  #{obj.key.ljust(20)} | \t\t   #{obj.storage_class.ljust(20)} \t\t| \t\t #{file_size}  \t\t| \t\t #{obj.last_modified}"
          end
        end
      end

    else
      NO_SUCH_BUCKET % bucket_name
    end
  when 'test'
    if options[:filter]
      filter = options[:filter]
      test = s3.buckets.select { |bucket| bucket.name =~ /#{filter}/ }
      puts "#{test}"
    end

  else
    puts "Unknown operation: '%s'!" % operation
    puts USAGE
end

# TODO
# Some additional features that could be useful (optional)
#
# It would be nice to support prefix in the bucket filter (e.g.: s3://mybucket/Folder/SubFolder/log*). It may also be useful to organize the results according to the encryption type, get additional buckets informations (life cycle, cross-region replication, etc.) or take into account the previous file versions in the count + size calculation.
#
#     Some statistics to check the percentage of space used by a bucket, or any other good ideas you could have, are more than welcome.

