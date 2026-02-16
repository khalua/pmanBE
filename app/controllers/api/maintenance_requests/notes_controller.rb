class Api::MaintenanceRequests::NotesController < Api::BaseController
  before_action :set_maintenance_request

  def index
    render json: @maintenance_request.notes.order(created_at: :asc).map { |note| note_json(note) }
  end

  def create
    note = @maintenance_request.notes.build(content: params[:content], user: current_user)
    if note.save
      NoteNotifier.call(note)
      render json: note_json(note), status: :created
    else
      render json: { errors: note.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_maintenance_request
    @maintenance_request = if current_user.tenant?
      current_user.maintenance_requests.find(params[:maintenance_request_id])
    elsif current_user.property_manager?
      MaintenanceRequest.joins(tenant: { unit: :property })
        .where(properties: { property_manager_id: current_user.id })
        .find(params[:maintenance_request_id])
    else
      MaintenanceRequest.find(params[:maintenance_request_id])
    end
  end

  def note_json(note)
    {
      id: note.id,
      content: note.content,
      user: { id: note.user.id, name: note.user.name, role: note.user.role },
      created_at: note.created_at
    }
  end
end
