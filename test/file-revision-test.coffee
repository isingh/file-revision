mock = require 'mock-fs'

fs = require 'fs'
glob = require 'glob'

setupFakeFileSystem = (fileSystem) ->
  mock(fileSystem)

destroyFakeFileSystem = () ->
  mock.restore()

filesInFileSystem = (path) ->
  availableFiles = []
  for filename in glob.sync(path? || './**')
    availableFiles.push filename if fs.statSync(filename).isFile()
  availableFiles

describe 'FileRevision', ->
  fileRevision = null

  describe 'createFileRevisions', ->
    afterEach ->
      destroyFakeFileSystem()

    describe 'when using queryString', ->
      fileSystemForQueryString =
        'rootfile.html': 'Some root directory file' # ff6d433fdb
        public:
          'index.html': 'Home Page' # cfe6e34a4c
          js:
            'app.js': 'App JS' # 82019350ea
            'vendor.js': 'some vendored JS' # 934e42cab5
            'app.js?revision=a1b2c3d4e5': 'an existing file'

      describe 'with default config', ->
        beforeEach (done) ->
          setTimeout( ->
            setupFakeFileSystem(fileSystemForQueryString)
            fileRevision = new FileRevision({})
            fileRevision.createFileRevisions()
            done()
          , 200)


        it 'generates the revisioned files', ->
          expect(filesInFileSystem()).to.include.members([
            './public/index.html?revision=cfe6e34a4c',
            './public/js/app.js?revision=82019350ea',
            './public/js/app.js?revision=a1b2c3d4e5',
            './public/js/vendor.js?revision=934e42cab5',
            './rootfile.html?revision=ff6d433fdb'
          ])

        it 'does not generate a revision for an existing revision', ->
          expect(filesInFileSystem().length).to.equal 5

      describe 'with specific input files', ->
        beforeEach (done) ->
          setTimeout( ->
            setupFakeFileSystem(fileSystemForQueryString)
            fileRevision = new FileRevision({inputPath: './public/**'})
            fileRevision.createFileRevisions()
            done()
          , 200)

        it 'ignores other files', ->
          expect(filesInFileSystem()).to.include.members([
            './public/index.html?revision=cfe6e34a4c',
            './public/js/app.js?revision=82019350ea',
            './public/js/app.js?revision=a1b2c3d4e5',
            './public/js/vendor.js?revision=934e42cab5',
            './rootfile.html'
          ])

        it 'does not generate a revision for an existing revision', ->
          expect(filesInFileSystem().length).to.equal 5

      describe 'with a input file match pattern', ->
        beforeEach (done) ->
          setTimeout( ->
            setupFakeFileSystem(fileSystemForQueryString)
            fileRevision = new FileRevision({matchPattern: /\.js$/})
            fileRevision.createFileRevisions()
            done()
          , 200)

        it 'ignores files that dont match patterns', ->
          expect(filesInFileSystem()).to.include.members([
            './public/index.html',
            './public/js/app.js?revision=82019350ea',
            './public/js/app.js?revision=a1b2c3d4e5',
            './public/js/vendor.js?revision=934e42cab5',
            './rootfile.html'
          ])

      describe 'with a manifest path', ->
        beforeEach (done) ->
          setTimeout( ->
            setupFakeFileSystem(fileSystemForQueryString)
            fileRevision = new FileRevision({manifestPath: './manifest.json'})
            fileRevision.createFileRevisions()
            done()
          , 200)

        it 'creates the manifest file', ->
          expect(fs.existsSync('./manifest.json')).to.equal true

      describe 'when retaining original files', ->
        beforeEach (done) ->
          setTimeout( ->
            setupFakeFileSystem(fileSystemForQueryString)
            fileRevision = new FileRevision({retainOriginal: true})
            fileRevision.createFileRevisions()
            done()
          , 200)

        it 'creates duplicate files', ->
          expect(filesInFileSystem()).to.include.members(
            ['./public/index.html',
             './public/index.html?revision=cfe6e34a4c',
             './public/js/app.js',
             './public/js/app.js?revision=82019350ea',
             './public/js/app.js?revision=a1b2c3d4e5',
             './public/js/vendor.js',
             './public/js/vendor.js?revision=934e42cab5',
             './rootfile.html',
             './rootfile.html?revision=ff6d433fdb'])

        it 'doesnt generate revision for existing revisioned file', ->
          expect(filesInFileSystem().length).to.equal 9

    describe 'when not using queryString', ->
      fileSystemForNonQueryString =
        'rootfile.html': 'Some root directory file' # ff6d433fdb
        public:
          'index.html': 'Home Page' # cfe6e34a4c
          js:
            'app.js': 'App JS' # 82019350ea
            'vendor.js': 'some vendored JS' # 934e42cab5
            'app-a1b2c3d4e5.js': 'an existing revisioned file'

      describe 'with default config', ->
        beforeEach (done) ->
          setTimeout( ->
            setupFakeFileSystem(fileSystemForNonQueryString)
            fileRevision = new FileRevision({revisionStyle: 'appendToFileName'})
            fileRevision.createFileRevisions()
            done()
          , 200)

        it 'generates the revisioned files', ->
          expect(filesInFileSystem()).to.include.members([
            './public/index-cfe6e34a4c.html',
            './public/js/app-82019350ea.js',
            './public/js/app-a1b2c3d4e5.js',
            './public/js/vendor-934e42cab5.js',
            './rootfile-ff6d433fdb.html'
          ])

        it 'does not generate a revision for an existing revision', ->
          expect(filesInFileSystem().length).to.equal 5

      describe 'with specific input files', ->
        beforeEach (done) ->
          setTimeout( ->
            setupFakeFileSystem(fileSystemForNonQueryString)
            fileRevision = new FileRevision({revisionStyle: 'appendToFileName', inputPath: './public/**'})
            fileRevision.createFileRevisions()
            done()
          , 200)

        it 'ignores other files', ->
          expect(filesInFileSystem()).to.include.members([
            './public/index-cfe6e34a4c.html',
            './public/js/app-82019350ea.js',
            './public/js/app-a1b2c3d4e5.js',
            './public/js/vendor-934e42cab5.js',
            './rootfile.html'
          ])

        it 'does not generate a revision for an existing revision', ->
          expect(filesInFileSystem().length).to.equal 5

      describe 'with a input file match pattern', ->
        beforeEach (done) ->
          setTimeout( ->
            setupFakeFileSystem(fileSystemForNonQueryString)
            fileRevision = new FileRevision({revisionStyle: 'appendToFileName', matchPattern: /\.js$/})
            fileRevision.createFileRevisions()
            done()
          , 200)

        it 'ignores files that dont match patterns', ->
          expect(filesInFileSystem()).to.include.members([
            './public/index.html',
            './public/js/app-82019350ea.js',
            './public/js/app-a1b2c3d4e5.js',
            './public/js/vendor-934e42cab5.js',
            './rootfile.html'
          ])

      describe 'with a manifest path', ->
        beforeEach (done) ->
          setTimeout( ->
            setupFakeFileSystem(fileSystemForNonQueryString)
            fileRevision = new FileRevision({revisionStyle: 'appendToFileName', manifestPath: './manifest.json'})
            fileRevision.createFileRevisions()
            done()
          , 200)

        it 'creates the manifest file', ->
          expect(fs.existsSync('./manifest.json')).to.equal true

      describe 'when retaining original files', ->
        beforeEach (done) ->
          setTimeout( ->
            setupFakeFileSystem(fileSystemForNonQueryString)
            fileRevision = new FileRevision({revisionStyle: 'appendToFileName', retainOriginal: true})
            fileRevision.createFileRevisions()
            done()
          , 200)

        it 'creates duplicate files', ->
          expect(filesInFileSystem()).to.include.members(
            ['./public/index.html',
             './public/index-cfe6e34a4c.html',
             './public/js/app.js',
             './public/js/app-82019350ea.js',
             './public/js/app-a1b2c3d4e5.js',
             './public/js/vendor.js',
             './public/js/vendor-934e42cab5.js',
             './rootfile.html',
             './rootfile-ff6d433fdb.html'])

        it 'doesnt generate revision for existing revisioned file', ->
          expect(filesInFileSystem().length).to.equal 9

