require 'locomotive/steam/middlewares/helpers'
require_relative  'cacher'

module LocomotiveEngineGeolocationLock
	module Helpers

		include ::Locomotive::Steam::Middlewares::Helpers

		def get_country_by_ip(remote_ip)

			cache_key = "getcountryip-#{remote_ip}"

			currentCountry = Cacher._get_by_key cache_key

			if currentCountry != nil
				return currentCountry
			else
				uri = URI.parse("https://freegeoip.net/json/#{remote_ip}")

				# Specify your own service
				uri = URI.parse(ENV['GEOLOCATION_URL'].dup % remote_ip) unless ENV['GEOLOCATION_URL'].nil?

				http = Net::HTTP.new(uri.host, uri.port)
				http.use_ssl = uri.scheme == 'https'

				request = Net::HTTP::Get.new(uri.request_uri)
				request["User-Agent"] = "arthrex-celltherapy-engine"

				resp = http.request(request)
				#Default / Fallback Country might be set up here
				currentCountry = ''
				if valid_json? resp.body
					jsonResp = JSON.parse resp.body
					if jsonResp["country_code"]
						currentCountry = jsonResp["country_code"]
					else jsonResp["country"]
						currentCountry = jsonResp["country"]
					end
				else
					::Rails.logger.warn 'The country of the IP '<< remote_ip<<' could not be solved'
				end
				Cacher._set_by_key(cache_key, currentCountry)
				return currentCountry
			end
		end
		def valid_json?(json)
			begin
				JSON.parse(json)
				return true
			rescue JSON::ParserError => e
				return false
			end
		end

		def redirect_to_page handle, type=301
			target_page = services.page_finder.by_handle handle, false
			unless target_page.nil?
				target_path = "/#{target_page.fullpath}"
				target_path = "/#{locale}#{target_path}" unless locale == default_locale
				redirect_to target_path, type	
			else
				raise "No site is set up with the handle '#{handle}'"
			end
		end
	end

end
