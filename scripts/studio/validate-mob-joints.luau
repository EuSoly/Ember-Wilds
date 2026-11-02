-- Read-only audit against the untouched pre-joint backup.
local source=game.ReplicatedStorage.Assets.Mobs
local backup=game.ServerStorage.MobsAntesDasJuntas
local EPS=0.001
local function frameError(a,b)
 local aa,bb={a:GetComponents()},{b:GetComponents()} local e=0
 for i=1,12 do e=math.max(e,math.abs(aa[i]-bb[i])) end return e
end
local function vectorError(a,b) local d=a-b return math.max(math.abs(d.X),math.abs(d.Y),math.abs(d.Z)) end
local function boxDistance(pos,model)
 local cf,size=model:GetBoundingBox()
 local p=cf:PointToObjectSpace(pos)
 local q=Vector3.new(math.max(math.abs(p.X)-size.X/2,0),math.max(math.abs(p.Y)-size.Y/2,0),math.max(math.abs(p.Z)-size.Z/2,0))
 return q.Magnitude
end
-- Supplementary diagnostic: the usual parent bounding box includes child groups.
-- Also measure only the parent's own layers to expose gaps hidden by that box.
local function directParentDistance(pos,model)
 local lo=Vector3.new(math.huge,math.huge,math.huge)
 local hi=Vector3.new(-math.huge,-math.huge,-math.huge)
 for _,part in ipairs(model:GetChildren()) do if part:IsA('MeshPart') then
  for x=-1,1,2 do for y=-1,1,2 do for z=-1,1,2 do
   local p=part.CFrame:PointToWorldSpace(part.Size*Vector3.new(x,y,z)/2)
   lo=lo:Min(p) hi=hi:Max(p)
  end end end
 end end
 return Vector3.new(math.max(lo.X-pos.X,0,pos.X-hi.X),math.max(lo.Y-pos.Y,0,pos.Y-hi.Y),math.max(lo.Z-pos.Z,0,pos.Z-hi.Z)).Magnitude
end
local result={}
for _,mob in ipairs(source:GetChildren()) do
 local old=backup:FindFirstChild(mob.Name) assert(old,"Missing backup "..mob.Name)
 local parts={} for _,p in ipairs(old:GetDescendants()) do if p:IsA('MeshPart') then assert(not parts[p.Name],"Duplicate backup mesh") parts[p.Name]=p end end
 local row={id=mob.Name,parts=0,groups=0,maxCFrameError=0,maxSizeError=0,maxColorError=0,maxRotationError=0,maxOwnBoxDistance=0,maxParentBoxDistance=0,maxMidHeightError=0,issues={}}
 local function issue(s) table.insert(row.issues,s) end
 row.maxDirectParentBoxDistance=0
 row.visualReviewNotes={}
 local children=mob:GetChildren()
 if #children~=1 or children[1].Name~='Body' or not children[1]:IsA('Model') then issue('Root must contain only Body') end
 if frameError(mob:GetPivot(),old:GetPivot())>EPS then issue('Mob pivot changed') end
 local seen={}
 for _,o in ipairs(mob:GetDescendants()) do
  if o:IsA('MeshPart') then
   row.parts+=1
   local before=parts[o.Name]
   if not before or seen[o.Name] then issue('Missing/duplicate mesh '..o.Name) else
    seen[o.Name]=true
    row.maxCFrameError=math.max(row.maxCFrameError,frameError(o.CFrame,before.CFrame))
    row.maxSizeError=math.max(row.maxSizeError,vectorError(o.Size,before.Size))
    row.maxColorError=math.max(row.maxColorError,vectorError(Vector3.new(o.Color.R,o.Color.G,o.Color.B),Vector3.new(before.Color.R,before.Color.G,before.Color.B)))
    if o.MeshId~=before.MeshId or o.TextureID~=before.TextureID or o.Material~=before.Material or o.Transparency~=before.Transparency or o.Reflectance~=before.Reflectance or o.Anchored~=before.Anchored or o.CanCollide~=before.CanCollide or o.CanTouch~=before.CanTouch or o.CanQuery~=before.CanQuery or o.Massless~=before.Massless then issue('Mesh/appearance/physics changed '..o.Name) end
   end
   if not o.Parent:IsA('Model') or o.Parent==mob then issue('Ungrouped '..o.Name) end
  elseif o:IsA('Model') then
   row.groups+=1
   local count=0 for _,d in ipairs(o:GetDescendants()) do if d:IsA('MeshPart') then count+=1 end end
   if count==0 then issue('Empty group '..o.Name) end
   local p=o:GetPivot()
   row.maxRotationError=math.max(row.maxRotationError,frameError(p.Rotation,CFrame.identity))
   row.maxOwnBoxDistance=math.max(row.maxOwnBoxDistance,boxDistance(p.Position,o))
   if o.Name=='Body' then
    if frameError(p,old:GetPivot())>EPS then issue('Body pivot differs from mob') end
   else
    row.maxParentBoxDistance=math.max(row.maxParentBoxDistance,boxDistance(p.Position,o.Parent))
    local directDistance=directParentDistance(p.Position,o.Parent)
    row.maxDirectParentBoxDistance=math.max(row.maxDirectParentBoxDistance,directDistance)
    if directDistance>.3+EPS then table.insert(row.visualReviewNotes,o.Name..': direct parent layers distance '..directDistance) end
    local cf=o:GetBoundingBox()
    row.maxMidHeightError=math.max(row.maxMidHeightError,math.abs(p.Y-cf.Y))
    local localX=old:GetPivot():PointToObjectSpace(p.Position).X
    if string.match(o.Name,'_R%d*$') and localX<0 then issue('Wrong R side '..o.Name) end
    if string.match(o.Name,'_L%d*$') and localX>0 then issue('Wrong L side '..o.Name) end
   end
  else issue('Unexpected instance '..o.ClassName) end
 end
 for name in pairs(parts) do if not seen[name] then issue('Lost mesh '..name) end end
 for _,key in ipairs({'maxCFrameError','maxSizeError','maxColorError','maxRotationError','maxMidHeightError'}) do if row[key]>EPS then issue(key..' exceeds tolerance: '..row[key]) end end
 if row.maxOwnBoxDistance>.3+EPS then issue('Own joint distance exceeds 0.3') end
 if row.maxParentBoxDistance>.3+EPS then issue('Parent joint distance exceeds 0.3') end
 row.pass=#row.issues==0
 table.insert(result,row)
 task.wait()
end
table.sort(result,function(a,b) return a.id<b.id end)
return result

