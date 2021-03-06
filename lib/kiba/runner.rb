module Kiba
  module Runner
    def run(control)
      sources = to_instances(control.sources)
      destinations = to_instances(control.destinations)
      transforms = to_instances(control.transforms, true)
      # not using keyword args because JRuby defaults to 1.9 syntax currently
      post_processes = to_instances(control.post_processes, true, false)

      sources.each do |source|
        source.each do |row|
          transforms.each_with_index do |transform, index|
            if transform.is_a?(Proc)
              row = transform.call(row)
            else
              row = transform.process(row)
            end
            break unless row
          end
          next unless row
          destinations.each do |destination|
            destination.write(row)
          end
        end
      end

      destinations.each(&:close)
      post_processes.each(&:call)
    end

    def to_instances(definitions, allow_block = false, allow_class = true)
      definitions.map do |d|
        case d
        when Proc
          raise "Block form is not allowed here" unless allow_block
          d
        else
          raise "Class form is not allowed here" unless allow_class
          d[:klass].new(*d[:args])
        end
      end
    end
  end
end