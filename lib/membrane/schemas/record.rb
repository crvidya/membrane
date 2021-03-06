require "set"

require "membrane/errors"
require "membrane/schemas/base"

module Membrane
  module Schema
  end
end

class Membrane::Schemas::Record < Membrane::Schemas::Base
  attr_reader :schemas
  attr_reader :optional_keys

  def initialize(schemas, optional_keys = [], strict_checking = false)
    @optional_keys = Set.new(optional_keys)
    @schemas = schemas
    @strict_checking = strict_checking
  end

  def validate(object)
    unless object.kind_of?(Hash)
      emsg = "Expected instance of Hash, given instance of #{object.class}"
      raise Membrane::SchemaValidationError.new(emsg)
    end

    key_errors = {}

    schema_keys = []
    @schemas.each do |k, schema|
      if object.has_key?(k)
        schema_keys << k
        begin
          schema.validate(object[k])
        rescue Membrane::SchemaValidationError => e
          key_errors[k] = e.to_s
        end
      elsif !@optional_keys.include?(k)
        key_errors[k] = "Missing key"
      end
    end

    if @strict_checking
      extra_keys = object.keys - schema_keys
      extra_keys.each do |k|
        key_errors[k] = "was not specified in the schema"
      end
    end

    if key_errors.size > 0
      emsg = "{ " + key_errors.map { |k, e| "#{k} => #{e}" }.join(", ") + " }"
      raise Membrane::SchemaValidationError.new(emsg)
    end
  end

  def parse(&blk)
    other_record = Membrane::SchemaParser.parse(&blk)
    @schemas.merge!(other_record.schemas)
    @optional_keys << other_record.optional_keys

    self
  end
end
