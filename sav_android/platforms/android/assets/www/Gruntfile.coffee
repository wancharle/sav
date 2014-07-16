module.exports = (grunt) ->
    grunt.loadNpmTasks('grunt-contrib-coffee')
    grunt.loadNpmTasks('grunt-contrib-watch')
    grunt.loadNpmTasks('grunt-contrib-jade')


    grunt.initConfig
        watch:
            coffee:
                files: 'src/*.coffee'
                tasks: ['coffee:compile']
            jade:
                files: 'src/*.jade'
                tasks: ['jade:compile']

        coffee:
            compile:
                expand: true,
                flatten: true,
                cwd: "#{__dirname}/src/",
                src: ['*.coffee'],
                dest: 'js/',
                ext: '.js'
        jade:
            compile:
                options:
                    pretty: true
                    data:
                        debug: true
                
                files: [
                    expand: true,
                    flatten: true,
                    cwd: "#{__dirname}/src/",
                    src: ['*.jade'],
                    dest: './',
                    ext: '.html'
                ]
