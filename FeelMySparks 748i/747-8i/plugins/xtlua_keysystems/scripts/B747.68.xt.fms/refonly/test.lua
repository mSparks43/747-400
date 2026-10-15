print("hello")
function split(s, delimiter)
  result = {};
  for match in (s..delimiter):gmatch("(.-)"..delimiter) do
      table.insert(result, match);
  end
  return result;
end



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
        retVal[line]=cLine
        line=line+1
        start=start+index
      else
        retVal[line]=cLine
        line=line+1
        start=start+24
      end
    end
    return retVal
  end

  local msgLines=convertToFMSLines("Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.")
local pgNo=2
    local start=(pgNo-1)*7
    local pageLines={}
    for i=1,7 do
      if start+i<=table.getn(msgLines) then
        pageLines[i]=msgLines[start+i]
      else
        pageLines[i]="                        "
      end
      print(pageLines[i])
    end