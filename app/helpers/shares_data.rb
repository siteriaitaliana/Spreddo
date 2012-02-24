class SharesData
  class << self
    def load_data
        shares_list_file = File.dirname(__FILE__) + '/shares.yml'
        @@shares = YAML.load_file shares_list_file
    end


    def method_missing(name)
      raise "Shares data not initialised" if @@shares.nil?
      @@shares.send :method_missing, name
    end
  end
end