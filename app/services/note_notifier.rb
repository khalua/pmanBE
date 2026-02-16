class NoteNotifier
  def self.call(note)
    new(note).call
  end

  def initialize(note)
    @note = note
    @mr = note.maintenance_request
    @author = note.user
  end

  def call
    recipients = []
    if @author.tenant?
      manager = @mr.tenant.unit&.property&.property_manager
      recipients << manager if manager
    else
      recipients << @mr.tenant
    end

    recipients.each do |user|
      PushNotificationService.notify(
        user: user,
        title: "New Message",
        body: "#{@author.name}: #{@note.content.truncate(80)}",
        data: { maintenance_request_id: @mr.id.to_s, type: "new_note" }
      )
    end
  end
end
