module Embulk
  module Parser

    class MysqldumpTab < ParserPlugin

      DUMMY_STRING         = "\v"
      FIELDS_TERMINATED_BY = "\t"
      FIELDS_ESCAPED_BY    = '\\'
      FIELDS_ENCLOSED_BY   = ''
      LINES_TERMINATED_BY  = "\n"

      Plugin.register_parser("mysqldump_tab", self)

      def self.transaction(config, &control)
        # configuration code:

        parser_task = config.load_config(Java::LineDecoder::DecoderTask)

        task = {
          "decoder_task" => DataSource.from_java(parser_task.dump)
          # "option1" => config.param("option1", :integer),                     # integer, required
          # "option2" => config.param("option2", :string, default: "myvalue"),  # string, optional
          # "option3" => config.param("option3", :string, default: nil),        # string, optional
        }

        # https://github.com/treasure-data/embulk-input-jira/blob/master/lib/embulk/input/jira.rb#L22
        attributes = {}
        columns = config.param(:columns, :array).map do |column|
          name = column["name"]
          type = column["type"].to_sym
          attributes[name] = type
          Column.new(nil, name, type, column["format"])
        end

        task[:attributes] = attributes

        # parser option
        # task[:option1] = config['option1']
        # task[:option1] = config.param(:option1, :integer, default: 5)

        yield(task, columns)
      end

      def init
        # initialization code:
        # @option1 = task["option1"]
        # @option2 = task["option2"]
        # @option3 = task["option3"]

        @decoder_task = task.param("decoder_task", :hash).load_task(Java::LineDecoder::DecoderTask)
      end

      def run(file_input)
        decoder = Java::LineDecoder.new(file_input.instance_eval { @java_file_input }, @decoder_task)

        while decoder.nextFile
          buffer = ''
          while line = decoder.poll
            buffer = buffer + line
            if in_column?(line)
              buffer = buffer.gsub(/#{Regexp.escape(FIELDS_ESCAPED_BY)}/, LINES_TERMINATED_BY)
              next
            end
            cols = parse_line(buffer)
            page_builder.add(cols)
            buffer = ''
          end

          # When output has not ended
          if buffer.length > 0
              cols = parse_line(buffer)
              page_builder.add(cols)
          end
        end

        page_builder.finish
      end

      private
      def parse_line(line)
        # Escape "escaped TAB" temporarily
        line = line.gsub(/\\#{FIELDS_TERMINATED_BY}/, DUMMY_STRING)

        # Split with separator (TAB)
        cols = line.split(FIELDS_TERMINATED_BY)
        cols.map! { |item| item.gsub(/#{DUMMY_STRING}/, FIELDS_TERMINATED_BY) }

        len = task[:attributes].length
        cols = adjust_column(cols, len)
        return cols
      end

      def in_column?(line)
        /#{Regexp.escape(FIELDS_ESCAPED_BY)}$/.match(line) ? true : false # escaped new line
      end

      # Adjust array length
      def adjust_column(arr, len)
        arr = arr.slice(0, len) # Truncate if more than len
        arr.fill(0, len) { |i| arr[i] } # If it is less than len, fill it with nil
      end

    end

  end
end
