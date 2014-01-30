require 'serverspec'

include Serverspec::Helper::Exec
include Serverspec::Helper::DetectOS

RSpec.configure do |c|
    c.before :all do
        c.path = '/sbin:/usr/sbin'
    end
end

describe "Git Daemon" do
    it "is listening on socket /var/run/docker.sock" do
        expect(socket('/var/run/docker.sock')).to be_listening
    end
    it "has a running service of docker" do
        expect(service("docker")).to be_running
    end

end