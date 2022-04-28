
function spirale(x,y,k)
local r = 1
while not (k<=(8*r)) do
r=r+1
end

n=2*r
--print("radius: "..r)
print("k mod     = "..math.mod(k-1,2*r))
if k<=n then
    print(k.."->1")
    return x+r,y-r+math.mod(k-1,2*r)
elseif k>n and k<=2*n then
    print(k.."->2")
    return x+r-math.mod(k-1,2*r),y+r
elseif k>2*n and k<=3*n then
    print(k.."->3")
    return x-r,y-r+math.mod(k-1,2*r)
elseif k>3*n then
    print(k.."->4")
    return x-r+math.mod(k-1,2*r),y+r
end

end



--- testaufruf
for i = 10, 18 do
print("-----------------------")
x,y=spirale(0,0,i)

print(i.."==>  "..x.."   :   "..y)
end
