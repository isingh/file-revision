crypto = require 'crypto'
fs = require 'fs'
glob = require 'glob'
path = require 'path'

class FileRevision
  constructor: (userProvidedConfig) ->
    # Load the provided config
    @loadConfig(userProvidedConfig)

  createFileRevisions: () ->
    @_generateRevisionFiles()

  # Load the user provided config and merge it with the defaults
  loadConfig: (userProvidedConfig) ->
    # Load some sane defaults
    @config =
      # The algorithm to use for getting file digest
      algorithm: 'md5'
      # Input encoding for the string
      inputEncoding: 'utf8'
      # Output encoding of the digest generate
      outputEncoding: 'hex'
      # Path to the manifest file to generate
      manifestPath: null
      # Path to the input files for revision
      inputPath: './**'
      # Pattern to use to select files for revisioning
      # If one is not provided, all files are considered for revisioning
      matchPattern: null
      # Create new files instead of renaming them
      retainOriginal: false
      # Choose how the revision is put in the filename
      revisionStyle: 'queryString'

    # Override the defaults with user provided config
    for key, value of userProvidedConfig
      @config[key] = value
    @config

  # Internal methods

  # Generate the files with revisions
  _generateRevisionFiles: ->
    eligibleFiles = @_eligibleFiles()
    manifest = @_generateManifest(eligibleFiles)
    for originalFileName, newFileName of manifest
      if @config.retainOriginal is true
        # If user specifies retainOriginal then we make a duplicate copy
        # of the file with the new digest name
        @_copyFile(originalFileName, newFileName, @_raiseError)
      else
        # Otherwise we simply rename the file to the digest name
        @_renameFile(originalFileName, newFileName, @_raiseError)

  # Rename a file
  _renameFile: (originalFileName, newFileName, callback) ->
    fs.rename(originalFileName, newFileName, @_raiseError)

  # Asynchronously copy a file
  _copyFile: (originalFileName, newFileName, callback) ->
    callbackCalled = false
    copyDone = (error) ->
      if !callbackCalled
        callback(error)
        callbackCalled = true

    # Input stream
    source = fs.createReadStream(originalFileName)
    source.on("error", copyDone)

    # Output stream
    target = fs.createWriteStream(newFileName)
    target.on("error", copyDone)
    target.on("close", (ex) -> copyDone())

    # Pipe the input to out
    source.pipe(target)

  # Get a list of available files in the directory provided
  _availableFiles: () ->
    availableFiles = []
    for filename in glob.sync(@config.inputPath)
      availableFiles.push filename if fs.statSync(filename).isFile()
    availableFiles

  # Eligible files
  _eligibleFiles: () ->
    eligibleFiles = []
    # Get all possible public files
    for file in @_availableFiles()
      fileName = path.basename(file)
      # Ensure the files match the user given pattern
      # and they are not already a digest file perhaps from the previous run
      if @_matchesPattern(fileName, @config.matchPattern) && !@_isDigestFile(fileName)
        eligibleFiles.push file
    eligibleFiles

  # Check if the input string matches the pattern
  # Return true if the pattern is null
  _matchesPattern: (stringForTest, pattern) ->
    return true unless pattern?
    pattern.test(stringForTest)

  # Check if the file is already a digest file
  # Look for the checksum in the filename
  _isDigestFile: (fileName) ->
    switch @config.revisionStyle
      when 'queryString' then /\?revision=[a-fA-F0-9]{10}$/.test fileName
      else /-[a-fA-F0-9]{10}$/.test path.basename(fileName, path.extname(fileName))

  # Generate the manifest for the files that need to have a digest
  # Save the manifest file if the user specified a path
  _generateManifest: (filesForDigest) ->
    manifest = @_fileDigestMap(filesForDigest)
    if @config.manifestPath?
      fs.writeFile(@config.manifestPath, JSON.stringify(manifest), @_raiseError)
    manifest

  # A hash map of public files that were eligible
  # and the new filename for them
  _fileDigestMap: (filesForDigest) ->
    fileDigestMap = {}
    for file in filesForDigest
      fileDigestMap[file] = @_addDigestToFileName(file, @_digestForFile(file))
    fileDigestMap

  # Get the new name of the file after appending the digest
  # to its original file name
  _addDigestToFileName: (file, digest) ->
    newFileName = file
    switch @config.revisionStyle
      when 'queryString'
        # Just append the revision as a query string
        # This will make directory/file.ext?revision=checksum
        newFileName += "?revision=#{digest}"
      else
        # In all other cases make the revision as part of the name
        # this will generate directory/file-checksum.ext
        fileExtension = path.extname(file)
        newFileName = "#{path.basename(file, fileExtension)}-#{digest}#{fileExtension}"
        newFileName = path.join(path.dirname(file), newFileName)
    newFileName

  # Get the checksum based on the file contents
  _digestForFile: (file) ->
    @_checksum(fs.readFileSync(file).toString())[0..9]

  # Get the checksum of the given string
  # Returns MD5 checksum be default, unless specified
  _checksum: (str) ->
    crypto
      .createHash(@config.algorithm)
      .update(str, @config.inputEncoding)
      .digest(@config.outputEncoding)

  _raiseError: (error) ->
    console.error error if error?

module.exports = FileRevision
