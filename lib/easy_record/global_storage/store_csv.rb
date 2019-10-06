module GlobalStorage
  module StoreCSV
    require 'csv'
    require 'snake_camel'
    require_relative '../record'

    def write_to_csv(headers, records)
      CSV.open(csv_filename, 'wb') do |csv|
        csv << headers
        records.each do |record|
          record.is_a?(Array) ? csv << record : csv << headers.map do |attr|
            record.send(attr)
          end
        end
      end
    end

    def save
      write_to_csv(instance_headers, self.all)
    end

    def load_from_csv
      p csv_structs
      read_from_csv.each do |record|
        self.new(record)
      end
    end

    def read_from_csv
      csv_body.map { |record| Hash[csv_headers.zip(record)] }
    end

    def save_record(record)
      return first_save(record) unless csv_exist?
      records = csv_structs
      to_replace = records.find { |row| row.id == record.id }
      unless to_replace.nil?
        records[records.index(to_replace)] = record
      else
        records << record
      end
      write_to_csv(csv_headers, records)
    end

    def first_save(record)
      write_to_csv(instance_headers, [record])
    end

    def destroy_record(record)
      records = csv_structs
      to_delete = records.find { |row| row.id == record.id }
      if records.delete_at(records.index(to_delete))
        write_to_csv(csv_headers, records)
        tracked = Record.of(class_name).find { |row| row.id == record.id }
        Record.untrack(tracked)
      end
    end

    def csv_index_of(record)
      csv_body.index(csv_body.find do |row|
        row[csv_headers.index('id')].to_i == record.id.to_i
      end) unless csv_body.nil?
    end

    def csv_exist?
      File.exist?(csv_filename)
    end

    def csv_contains?(record)
      csv_contains_id?(record.id)
    end

    def csv_cantains_id?(id)
      csv_body.any? { |row| row[csv_headers.index('id')] == id }
    end

    def csv_filename
      "./#{class_name.snakecase}.csv"
    end

    def csv_raw
      { headers: csv_headers, body: csv_body }
    end

    private

    def csv_structs
      struct = Struct.new(class_name, *csv_headers)
      csv_body.each_with_index.map do |row, index|
        struct.new(*row)
      end
    end

    def csv_headers
      csv_exist? ? csv_data.to_a.shift : instance_headers
    end

    def csv_body
      csv_data.to_a[1..-1] unless csv_data.nil?
    end

    def class_name
      self.name
    end

    def csv_data
      CSV.read(csv_filename, headers: true) if csv_exist?
    end

    def instance_headers
      self.first.instance_variables.map { |var| var.to_s[1..-1] }
    end
  end
end
