require File.expand_path('../../../spec_helper', File.dirname(__FILE__))

describe Trinidad::Lifecycle::WebApp::War do

  it "configures classloader" do
    context = new_web_app_context('/')
    listener = Trinidad::Lifecycle::WebApp::War.new(new_web_app)
    
    listener.send :configure_class_loader, context
    expect( context.loader ).to_not be nil
  end

  it "configures class-loader (on configure)" do
    context = new_web_app_context('/')
    context.name = 'default'
    listener = Trinidad::Lifecycle::WebApp::War.new(new_web_app)

    listener.stubs(:configure_default_servlet)
    listener.stubs(:configure_jsp_servlet)
    listener.send(:configure, context)

    expect( context.loader ).to_not be nil
  end

  # it "creates the log directory under the WEB-INF directory" do
  #   begin
  #     Dir.mkdir('apps_base')
  #     Dir.mkdir('apps_base/foo')
  #     Dir.mkdir('apps_base/foo/WEB-INF')
  #
  #     web_app = new_web_app({
  #       :context_path => '/foo.war',
  #       :root_dir => File.expand_path('apps_base/foo.war'),
  #       :environment => 'production'
  #     })
  #     context = new_web_app_context('/foo.war')
  #     listener = Trinidad::Lifecycle::WebApp::War.new(web_app)
  #     logger = listener.send :configure_logging, context
  #     logger.info "greetings!"
  #
  #     File.exist?('apps_base/foo/WEB-INF/log').should be true
  #   ensure
  #     FileUtils.rm_rf('apps_base')
  #   end
  # end

  it "makes sure context name is same as path" do
    # NOTE: this is important due :
    #
    # public ProxyDirContext(Hashtable<String,String> env, DirContext dirContext) {
    #     ...
    #     hostName = env.get(HOST);
    #     contextName = env.get(CONTEXT);
    #     int i = contextName.indexOf('#');
    #     if (i == -1) {
    #         contextPath = contextName;
    #     } else {
    #         contextPath = contextName.substring(0, i);
    #     }
    # }
    #
    # since the contextPath is constructed from the name instead of the context.path
    # this messed up resource resolution ... with DirContextURLConnection.connect !
    #
    # ending up as errors reported while scanning WEB-INF/lib .jar files e.g. :
    #
    #   Failed to scan JAR [jndi:/localhost/petclinic/WEB-INF/lib/jstl-1.1.2.jar] from WEB-INF/lib
    #   java.io.FileNotFoundException: jndi:/localhost/petclinic/WEB-INF/lib/jstl-1.1.2.jar
    #
    context = new_web_app_context('/')
    context.name = 'default'
    listener = Trinidad::Lifecycle::WebApp::War.new(new_web_app)
    
    event = mock 'event'
    event.stubs(:type).returns Trinidad::Tomcat::Lifecycle::BEFORE_INIT_EVENT
    event.stubs(:lifecycle).returns context
    listener.lifecycleEvent(event)

    expect( context.path ).to eql '/'
    expect( context.name ).to eql '/'

    listener.send(:adjust_context, context)

    expect( context.path ).to eql '/'
    expect( context.name ).to eql '/'
  end
  
  private

  let(:tomcat) { Trinidad::Tomcat::Tomcat.new }

  def new_web_app(config = {})
    Trinidad::WarWebApp.new(config)
  end

  def new_web_app_context(context_path)
    tomcat.add_webapp(context_path, MOCK_WEB_APP_DIR)
  end
  
end

describe "Trinidad::Lifecycle::War" do
  it "still works" do
    Trinidad::Lifecycle::War.should == Trinidad::Lifecycle::WebApp::War
  end
end
