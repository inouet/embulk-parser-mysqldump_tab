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
        }

        # see https://github.com/treasure-data/embulk-input-jira/blob/master/lib/embulk/input/jira.rb#L22
        attributes = {}
        columns = config.param(:columns, :array).map do |column|
          name = column["name"]
          type = column["type"].to_sym
          attributes[name] = type
          Column.new(nil, name, type, column["format"])
        end

        task[:attributes] = attributes
        task[:columns] = columns

        yield(task, columns)
      end

      def init
        # initialization code:
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

        cols = make_record(cols)
      end

      def in_column?(line)
        /#{Regexp.escape(FIELDS_ESCAPED_BY)}$/.match(line) ? true : false # escaped new line
      end

      # see https://github.com/takumakanari/embulk-parser-json/blob/master/lib/embulk/parser/jsonpath.rb#L43
      def make_record(arr)
        columns = @task[:columns]
        record = columns.map.with_index do |col, i|
          val  = cast_value(arr[i], col)
        end
      end

      def cast_value(val, col)
        type = col["type"]
        fmt  = col["format"]

        case type
        when "string"
          val
        when "long"
          val.to_i
        when "double"
          val.to_f
        when "json"
          val
        when "boolean"
          if kind_of_boolean?(val)
            val
          elsif val.nil? || val.empty?
            nil
          elsif val.kind_of?(String)
            ["yes", "true", "1"].include?(val.downcase)
          elsif val.kind_of?(Numeric)
            !val.zero?
          else
            !!val
          end
        when "timestamp"
          if val.nil? || val.empty?
            nil
          else
            begin
              Time.strptime(val, fmt)
            rescue ArgumentError => e
              #raise DataParseError.new e
              nil
            end
          end
        else
          raise "Unsupported type #{type}"
        end
      end

      def kind_of_boolean?(val)
        val.kind_of?(TrueClass) || val.kind_of?(FalseClass)
      end

      class DataParseError < StandardError
      end

    end
  end
end
