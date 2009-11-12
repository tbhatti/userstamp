module ActiveRecord
  # Active Record automatically userstamps create and update operations if the table has fields
  # named created_by or updated_by.
  #
  # Userstamping can be turned off by setting
  #   <tt>ActiveRecord::Base.record_userstamps = false</tt>
  module Userstamp
    def self.included(base) #:nodoc:
      super
      base.extend ClassMethods
      base.send(:include, InstanceMethods)

      base.alias_method_chain :create, :userstamps
      base.alias_method_chain :update, :userstamps

      base.class_inheritable_accessor :record_userstamps, :instance_writer => false
      base.record_userstamps = true
    end

    module ClassMethods
      def set_user_model_name(name)
        self.user_model_name = name
      end

      def stampable
        class_eval do
          belongs_to :creator, :class_name => "User", :foreign_key => "created_by"
          belongs_to :updater, :class_name => "User", :foreign_key => "updated_by"
        end
      end
    end

    module InstanceMethods
      def creator
        self.class.stampable
        creator
      end

      def updater
        self.class.stampable
        updater
      end
    end

    private
      def create_with_userstamps #:nodoc:
        if record_userstamps
          current_user = User.current_user
          unless current_user.nil?
            t = current_user.id
            write_attribute('created_by', t) if respond_to?(:created_by) && created_by.nil?
            write_attribute('updated_by', t) if respond_to?(:updated_by) && updated_by.nil?
          end
        end
        create_without_userstamps
      end

      def update_with_userstamps(*args) #:nodoc:
        if record_userstamps && (!partial_updates? || changed?)
          write_attribute('updated_by', t) if respond_to?(:updated_by)
        end
        update_without_userstamps(*args)
      end
  end
end

