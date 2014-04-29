# Copyright (c) 2011, salesforce.com, inc.
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without modification, are permitted provided
# that the following conditions are met:
#
#    Redistributions of source code must retain the above copyright notice, this list of conditions and the
#    following disclaimer.
#
#    Redistributions in binary form must reproduce the above copyright notice, this list of conditions and
#    the following disclaimer in the documentation and/or other materials provided with the distribution.
#
#    Neither the name of salesforce.com, inc. nor the names of its contributors may be used to endorse or
#    promote products derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED
# WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A
# PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED
# TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
# NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
class CanvasController < ApplicationController
  # GET /canvas
  def index
    @authStatus = params[:_sfdc_canvas_auth]
    # Check if canvas is reporting that the user must approve the app first.
    # This is done by adding _sfdc_canvas_auth=user_approval_required to the
    # query string.
    if @authStatus.eql?("user_approval_required")
      # Retrieve consumer key from environment. We need this
      # for oauth flow.
      @consumerKey = ENV["CANVAS_CONSUMER_KEY"]
      raise "No consumer key found in environment [CANVAS_CONSUMER_KEY]." if @consumerKey.blank?()
      render "user-approval"
    else
      render "index"
    end
    
  end

  # POST /canvas
  def post
    @sr = params[:signed_request]

    # Validate the signed request was provided.
    raise "Signed request parameter required." if @sr.blank?()

    # Retrieve consumer secret from environment
    secret = ENV["CANVAS_CONSUMER_SECRET"]
    raise "No consumer secret found in environment [CANVAS_CONSUMER_SECRET]." if secret.blank?()

    # Construct the signed request helper
    srHelper = SignedRequest.new(secret,@sr)

    # Verify and decode the signed request.
    @canvasRequestJson = srHelper.verifyAndDecode()
    
    @canvasRequest = JSON.parse(@canvasRequestJson)
    
    # Parse user-agent header using useragent gem.  You can use this
    # to determine if mobile device.
    @ua = UserAgent.parse(request.user_agent)
    
    location = @canvasRequest["context"]["environment"]["displayLocation"]
      
    # Now, we check if a template exists to handle the current display location
    # i.e. MobileNav/index, Publisher/index, etc.  If not, just render default.
    templateExists = template_exists?("index",location)
    if templateExists
      render location+"/index"
    else
      render "default/index"
    end
  end

end
