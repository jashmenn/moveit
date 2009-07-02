require 'spec'

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'moveit'

FIXTURES_DIR = File.dirname(__FILE__) + "/fixtures"

Spec::Runner.configure do |config|
  
end
