task :run_crawler => :environment do
  state = 'california'
  agent = Mechanize.new { |agent|
    agent.user_agent_alias = 'Mac Safari'
  }
  city_list = []
  firm_list = []
  over_sized_firm_list = []

  page_num = 2
  has_firms = false

  agent.get("http://www.lawyers.com/#{state}/find-law-firms-by-city/") do |page|
    res = page.search('#panelCities li a').map {|link| link['href'].split('/')[1]}
    if res.count > 0
      city_list += res
    end
  end

  city_list.reject {|city| city == '' || city.nil? }.each do |city|
    page = agent.get("http://www.lawyers.com/all-legal-issues/#{city}/#{state}/law-firms/")
    res = page.search('div#searchResults h1').first
    if res.nil?
      next
    end
    num_firms = res.text
    num_firms = /\(([^)]+)\)/.match(num_firms).captures.first.tr(',', '').to_i
    if num_firms > 500
      over_sized_firm_list << { city => num_firms}
      next
    end
    res = page.search('#searchResults .title a').map {|link| link['href']}
    if res.count > 0
      firm_list += res
      has_firms = true
    end

    begin
      while has_firms
        agent.get("http://www.lawyers.com/all-legal-issues/san-diego/#{state}/law-firms-p#{page_num}") do |page|
          res = page.search('#divSearchResults a.b').map {|link| link['href']}
          if res.count > 0
            firm_list = firm_list + res
            page_num += 1
          else
            has_firms = false
          end
        end
      end
    rescue Mechanize::ResponseCodeError => e
    end
  end
end