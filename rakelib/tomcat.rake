require 'open-uri'
require 'tmpdir'

namespace :tomcat do
  
  TOMCAT_CORE_PATH = File.expand_path('../../trinidad-libs/tomcat-core.jar', __FILE__)
  TOMCAT_MAVEN_REPO = 'http://repo2.maven.org/maven2/org/apache/tomcat'

  tomcat = "#{TOMCAT_MAVEN_REPO}/embed/tomcat-embed-core/%s/tomcat-embed-core-%s.jar"
  tomcat_jasper = "#{TOMCAT_MAVEN_REPO}/embed/tomcat-embed-jasper/%s/tomcat-embed-jasper-%s.jar"
  tomcat_logging = "#{TOMCAT_MAVEN_REPO}/embed/tomcat-embed-logging-log4j/%s/tomcat-embed-logging-log4j-%s.jar"

  dependencies = [tomcat, tomcat_jasper, tomcat_logging]
  
  desc "Updates Tomcat to a given version"
  task :update, :version do |task, args|
    tomcat_version = [args[:version]] * 2

    Dir.chdir(Dir.tmpdir) do
      dependencies.each do |dependency|
        dependency_path = dependency % tomcat_version
        dependency_name = dependency_path.split('/').last

        # dowload dependencies
        puts "downloading #{dependency_path}"
        file = open(dependency_path)
        %x{jar -xf #{file.path}}
      end

      # build the jar again
      puts "building the tomcat's core jar"
      %x{jar -cvf #{TOMCAT_CORE_PATH} META-INF javax org}
    end

    puts "updating tomcat's version number to #{tomcat_version.first}"
    path = File.expand_path('../../lib/trinidad/jars.rb', __FILE__)
    file = File.read(path)
    file.gsub!(/TOMCAT_VERSION = '(.+)'/, "TOMCAT_VERSION = '#{tomcat_version.first}'")
    File.open(path, 'w') { |io| io.write(file) }

    puts "DONE - Tomcat's version has been updated succesfully, please build Trinidad again."
  end
  
end