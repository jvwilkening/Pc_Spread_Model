%finds index location of given date in climate data
function index=find_index(yr, mth, dy, year, month, day)
index=0;

for i=1:length(year)
    if year(i)==yr && month(i)==mth && day(i)==dy
        index=i;
        break
    end
end