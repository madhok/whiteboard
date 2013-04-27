# If no search parameters were provided, the most useful default contacts for that user is shown.
# this is implemented in the people search pages
#
# == Related classes
# {Person Controller}[link:classes/PeopleController.html]
#
class PeopleSearchDefault < ActiveRecord::Base
  belongs_to :user
  validates_presence_of :student_staff_group, :user_id

  def self.default_search_results(user)
    # Grab all records from the people_search_defaults table
    search_defaults = PeopleSearchDefault.all

    # Save "all" records for student_staff_group into results and reject from search_defaults list to move forward.
    results = search_defaults.find_all { |t| t.student_staff_group == 'All' }
    search_defaults.reject!  { |t| t.student_staff_group == 'All' }
    if(user.is_student)

      # Filter to only students
      search_defaults = search_defaults.find_all { |t| t.student_staff_group == 'Student' }

      # Save "all" records for program_group into results and reject from search_defaults list to move forward.
      search_defaults.find_all { |t| t.program_group == 'All' }.each { |x| results.push(x) }
      search_defaults.reject!  { |t| t.program_group == 'All' }

      # Filter to only students in same master program as user
      search_defaults = search_defaults.find_all { |t| t.program_group == user.masters_program }

      # Save "all" records for track_group into results and reject from search_defaults list to move forward.
      search_defaults.find_all { |t| t.track_group == 'All' }.each { |x| results.push(x) }
      search_defaults.reject!  { |t| t.track_group == 'All' }

      # Filter to only students in same master's track as user
      search_defaults = search_defaults.find_all { |t| t.track_group == user.masters_track || (user.masters_program == 'PhD' && t.track_group == nil) }.each { |x| results.push(x) }

    else
      # Filter to only staff and save
      search_defaults = search_defaults.find_all { |t| t.student_staff_group == 'Staff' }
      search_defaults.each { |x| results.push(x) }
    end
    # remove user if he would see himself and return.
    results.reject{ |t| t.user_id == user.id }
  end

  def self.get_default_key_contacts(current_user)
    @user = current_user
    if (current_user.is_admin? || current_user.is_staff?)
      if !params[:id].blank?
        @user_override = true
        @user = User.find_by_param(params[:id])
      end
    end
    results = default_search_results(@user)
  end

  def self.get_key_contact_results(user)
    @people = get_default_key_contacts(user)
    @people.collect { |default_person| Hash[
        :image_uri => image_path(default_person.user.image_uri),
        :title => default_person.user.title,
        :human_name => default_person.user.human_name,
        :contact_dtls => default_person.user.telephones_hash,
        :email => default_person.user.email,
        :path => person_path(default_person.user),
        # first_name and last_name required for photobook view
        :first_name => default_person.user.first_name,
        :last_name => default_person.user.last_name
    ]}
  end
end
