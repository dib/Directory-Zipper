require 'rubygems'
require 'zip/zip'
require 'ostruct'

EXCLUSIONS = [".","..",".DS_Store"]
options = OpenStruct.new

def zip_directories(path, destination)
  return unless Dir.exists?(path) && Dir.exists?(destination)
  d = Dir.new(path)
  d.each do |entry|
    dir_path = File.join(path, entry)
    destination_path = File.join(destination, entry + ".zip")

    next unless Dir.exists?(dir_path) && !EXCLUSIONS.include?(entry)

    zf = ZipFileGenerator.new(dir_path, destination_path)
    zf.write()
  end
end

def get_options
  OptionParser.new do |opts|
    opts.banner = "Usage: zip.rb -i [INPUT DIRECTORY] -o [OUTPUT DIRECTORY]"

    opts.on("-i [INPUT DIRECTORY]") do |input_directory|
      options.input_directory = input_directory
    end
    opts.on("-m [OUTPUT DIRECTORY]") do |output_directory|
      options.output_directory = output_directory
    end
  end.parse!

  return options.input_directory && options.output_directory
end

class ZipFileGenerator

  # Initialize with the directory to zip and the location of the output archive.
  def initialize(inputDir, outputFile)
    @inputDir = inputDir
    @outputFile = outputFile
  end

  # Zip the input directory.
  def write()
    entries = Dir.entries(@inputDir); entries.delete("."); entries.delete("..") 
    io = Zip::ZipFile.open(@outputFile, Zip::ZipFile::CREATE); 

    writeEntries(entries, "", io)
    io.close();
  end

  # A helper method to make the recursion work.
  private
  def writeEntries(entries, path, io)
    
    entries.each { |e|
      zipFilePath = path == "" ? e : File.join(path, e)
      diskFilePath = File.join(@inputDir, zipFilePath)
      puts "Deflating " + diskFilePath
      if  File.directory?(diskFilePath)
        io.mkdir(zipFilePath)
        subdir =Dir.entries(diskFilePath); subdir.delete("."); subdir.delete("..") 
        writeEntries(subdir, zipFilePath, io)
      else
        io.get_output_stream(zipFilePath) { |f| f.puts(File.open(diskFilePath, "rb").read())}
      end
    }
  end
    
end

if get_options
  zip_directories(options.input_directory, options.output_directory)
end
