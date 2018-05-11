module Agent::TranslationsHelper
  def progress(missing, total)
    begin
      percent = (total.to_f - missing.to_f) / total.to_f * 100
      return percent.to_i
    rescue
      return 0
    end
  end
end
