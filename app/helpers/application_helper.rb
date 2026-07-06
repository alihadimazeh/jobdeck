module ApplicationHelper
  def nav_link(label, path, active)
    base = "flex items-center gap-2 px-3 py-2 rounded-md text-sm font-medium transition-colors"
    style = active ? "bg-white/10 text-white" : "text-gray-400 hover:text-white hover:bg-white/5"
    link_to(label, path, class: "#{base} #{style}")
  end
end
