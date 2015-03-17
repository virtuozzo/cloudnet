module TicketsHelper
  def form_departments
    Helpdesk.departments.map do |k, v|
      [v[:name], k.to_s]
    end
  end

  def department_name(key)
    departments = Helpdesk.departments

    if departments.key?(key)
      return departments[key][:name]
    else
      return 'Unknown'
    end
  end
end
