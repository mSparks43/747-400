-- test.lua
-- scratchpad for testing lua code
function str_trim(s)
	return string.match(s,'^()%s*$') and '' or string.match(s,'^%s*(.*%S)')
end
noPages=math.ceil(7/7)
print(noPages)
function convertToFMSLines(msg)
    local retVal={}
    local line=1
    local start=1
    local endI=string.len(msg)
    while start<endI do
      local cLine=string.sub(msg,start,start+24)
      local index = string.find(cLine, " [^ ]*$")
      if index~=nil and index > 10 then
        cLine=string.sub(msg,start,start+index-1)
        local atindex = string.find(cLine, "@")
        if atindex~=nil then
            cLine=string.sub(msg,start,start+atindex-2)
            start=start+atindex
        else
            start=start+index
        end
        retVal[line]=str_trim(cLine)
        line=line+1
      else
        local atindex = string.find(cLine, "@")
        if atindex~=nil then
            cLine=string.sub(msg,start,start+atindex-2)
            start=start+atindex
        else
            start=start+24
        end    
        retVal[line]=str_trim(cLine)
        if string.len(retVal[line])>0 then
            line=line+1
        end
      end
    end
    return retVal
  end

  local testMSG=convertToFMSLines("The quick brown @fo@x jumped over the lazy @dog@ Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.")
  for i=1,#testMSG,1 do
    print(testMSG[i])
  end


noPages=math.ceil(8/7)
print(noPages)