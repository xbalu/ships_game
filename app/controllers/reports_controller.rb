class ReportsController < ApplicationController
  before_action :authenticate_user!
  before_action :check_if_user_is_admin, only: [:index, :destroy]

  def new
    @report = Report.new
  end

  def create
    @report = Report.new(report_params)
    @report.user_id = current_user.id

    if @report.save
      flash[:notice] = "Your report has been sent, thank you"
      redirect_to new_report_url
    else
      render "reports/new"
    end
  end

  def index
    @reports = Report.all.order(created_at: :desc).paginate(:page => params[:page], :per_page => 10)
  end

  def destroy
    report = Report.find(params[:id])
    report.delete
    redirect_to reports_path
  end

  private

  def report_params
    params.require(:report).permit(:text)
  end
end
