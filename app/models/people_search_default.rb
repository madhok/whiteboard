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

  def self.callRespond_to(params, user, format)
    if(user.nil?)
      flash[:error] = "Person with an id of #{params[:id]} is not in this system."
      format.html { redirect_to(people_url) }
      format.xml { render :xml => user.errors, :status => :unprocessable_entity }
    else
      format.html # show.html.erb
      format.xml { render :xml => user }
      format.json { render :json => user, :layout => false }
    end

  end


  def self.createPerson( params)

    authorize! :create, User

    @person = User.new
    @person.is_active = true
    @person.webiso_account = params[:webiso_account]
    @person.personal_email = params[:personal_email]
    @person.is_student = params[:is_student]
    @person.first_name = params[:first_name]
    @person.last_name = params[:last_name]
    @person.masters_program = params[:program]
    @person.expires_at = params[:expires_at]
    return @person
  end

  def self.setAttributes(user, params,format)
    user.attributes = params[:user]
    user.photo = params[:user][:photo] if can? :upload_photo, User
    user.expires_at = params[:user][:expires_at] if current_user.is_admin?

    if user.save
      unless user.is_profile_valid
        flash[:error] = "Please update your (social handles or biography) and your contact information"
      end
      flash[:notice] = 'Person was successfully updated.'
      format.html { redirect_to(user) }
      format.xml { head :ok }
    else
      format.html { render :action => "edit" }
      format.xml { render :xml => user.errors, :status => :unprocessable_entity }
    end
  end

  def createAndSetPerson(params,current_user)
    authorize! :create, User
    @person = User.new(params[:user])
    @person.updated_by_user_id = current_user.id
    @person.image_uri = "/images/mascot.jpg"
    @person.biography = "<p>I was raised by sheepherders on the hills of BoingBoing while they were selling chunky bacon. Because I have a ring, I need help with putting on my clothes. After working hard they promoted me to garbage man. They told me the reason for this new responsibility was show me the money. I looked for a treasure map and tools, but I never did find the fourteen minutes. People's trash clearly isn't multitudinous. I hope to put my real biography here one day.</p>"
    if @person.is_student
      @person.user_text = "<h2>About Me</h2><p>I'd like to accomplish the following three goals (professional or personal) by the time I graduate:<ol><li>Goal 1</li><li>Goal 2</li><li>Goal 3</li></ol></p>"
    end
  end
end
