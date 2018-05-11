module Listing::LocationsHelper
	def map_visibility(visibility)
		if visibility == 'guests'
			return content_tag(:span, t('listing.map_publicly_visible'), class: 'map-visibility label label-success')
		end
		if visibility == 'members'
			return content_tag(:span, t('listing.map_visible_members'), class: 'map-visibility label label-warning')
		end
		if visibility == 'hidden'
			return content_tag(:span, t('listing.map_hidden_for_all'), class: 'map-visibility label label-important')
		end
	end
end
