require 'foreigner/connection_adapters/sql_2003'

module Foreigner
  module ConnectionAdapters
    module PostgreSQLAdapter
      include Foreigner::ConnectionAdapters::Sql2003
      
      def foreign_keys(table_name)
        foreign_keys = []

        fk_info = select_all %{
          select tc.constraint_name as name
                ,ccu.table_name as to_table
                ,kcu.column_name as column
                ,rc.delete_rule as dependency
          from information_schema.table_constraints tc
          join information_schema.key_column_usage kcu
            on tc.constraint_catalog = kcu.constraint_catalog
           and tc.constraint_schema = kcu.constraint_schema
           and tc.constraint_name = kcu.constraint_name
          join information_schema.referential_constraints rc
            on tc.constraint_catalog = rc.constraint_catalog
           and tc.constraint_schema = rc.constraint_schema
           and tc.constraint_name = rc.constraint_name
          join information_schema.constraint_column_usage ccu
            on tc.constraint_catalog = ccu.constraint_catalog
           and tc.constraint_schema = ccu.constraint_schema
           and tc.constraint_name = ccu.constraint_name
          where tc.constraint_type = 'FOREIGN KEY'
            and tc.constraint_catalog = '#{@config[:database]}'
            and tc.table_name = '#{table_name}'
        }
        
        fk_info.inject([]) do |foreign_keys, row|
          options = {:column => row['column'], :name => row['name']}
          if row['dependency'] == 'CASCADE'
            options[:dependent] = :delete
          elsif row['dependency'] == 'SET NULL'
            options[:dependent] = :nullify
          end
          foreign_keys << ForeignKeyDefinition.new(table_name, row['to_table'], options)
        end
      end
    end
  end
end

module ActiveRecord
  module ConnectionAdapters
    PostgreSQLAdapter.class_eval do
      include Foreigner::ConnectionAdapters::PostgreSQLAdapter
    end
  end
end