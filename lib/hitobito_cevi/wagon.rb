# encoding: utf-8

#  Copyright (c) 2012-2014, CEVI Regionalverband ZH-SH-GL. This file is part of
#  hitobito_cevi and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito_cevi.

module HitobitoCevi
  class Wagon < Rails::Engine
    include Wagons::Wagon

    # Set the required application version.
    app_requirement '>= 0'

    # Add a load path for this specific wagon
    config.autoload_paths += %W( #{config.root}/app/abilities
                                 #{config.root}/app/domain
                                 #{config.root}/app/serializers )


    config.to_prepare do
      # extend application classes here
      # models
      Group.send :include, Cevi::Group
      Person.send :include, Cevi::Person
      Role.send :include, Cevi::Role

      Event::Kind.send :include, Cevi::Event::Kind
      Event::Course.send :include, Cevi::Event::Course
      Event::Role::AssistantLeader.permissions = [:participations_read]

      # :financials may edit all people in a Group::Spender group.
      # :unconfined_below may edit below people even when they have visible_from_above = false.
      #   This only makes sense with :layer_and_below_full.
      Role::Permissions << :financials << :unconfined_below

      # abilities
      EventAbility.send :include, Cevi::EventAbility
      GroupAbility.send :include, Cevi::GroupAbility
      PersonAbility.send :include, Cevi::PersonAbility
      RoleAbility.send :include, Cevi::RoleAbility
      VariousAbility.send :include, Cevi::VariousAbility
      Event::ParticipationAbility.send :include, Cevi::Event::ParticipationAbility
      PersonReadables.send :include, Cevi::PersonReadables
      PersonLayerWritables.send :include, Cevi::PersonLayerWritables
      AbilityDsl::Base.send :include, Cevi::AbilityDsl::Base

      # domain
      Event::ParticipationFilter.load_entries_includes.each do |incl|
        if incl.is_a?(Hash) && incl.key?(:person)
          incl[:person].prepend :ortsgruppe
        end
      end
      Export::Tabular::People::PersonRow.send :include, Cevi::Export::Tabular::People::PersonRow
      Export::Tabular::People::PeopleAddress.send(
        :include, Cevi::Export::Tabular::People::PeopleAddress)
      Export::Tabular::People::ParticipationNdbjsRow.send(
        :include, Cevi::Export::Tabular::People::ParticipationNdbjsRow)
      Import::Person.send :include, Cevi::Import::Person

      # serializers
      PersonSerializer.send :include, Cevi::PersonSerializer
      PeopleSerializer.send :include, Cevi::PeopleSerializer
      GroupSerializer.send :include, Cevi::GroupSerializer
      EventParticipationSerializer.send :include, Cevi::EventParticipationSerializer

      # controllers
      EventsController.send :include, Cevi::EventsController
      Event::KindsController.permitted_attrs += [:j_s_label]
      Event::ParticipationsController.send :include, Cevi::Event::ParticipationsController

      PeopleController.send :include, Cevi::PeopleController

      # jobs
      Export::EventParticipationsExportJob.send :include, Cevi::Export::EventParticipationsExportJob

      # helpers
      Sheet::Group.send :include, Cevi::Sheet::Group

      # decorators
      PaperTrail::VersionDecorator.send :include, Cevi::PaperTrail::VersionDecorator
    end

    initializer 'cevi.add_settings' do |_app|
      Settings.add_source!(File.join(paths['config'].existent, 'settings.yml'))
      Settings.reload!
    end

    initializer 'jubla.add_inflections' do |_app|
      ActiveSupport::Inflector.inflections do |inflect|
        inflect.irregular 'census', 'censuses'
      end
    end

    private

    def seed_fixtures
      fixtures = root.join('db', 'seeds')
      ENV['NO_ENV'] ? [fixtures] : [fixtures, File.join(fixtures, Rails.env)]
    end

  end
end
