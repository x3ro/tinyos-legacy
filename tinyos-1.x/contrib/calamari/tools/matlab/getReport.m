function getReport(reportType, addr)
%reportType = {'ident', 'service', 'anchors', 'ranging', 'rangingValues', 'location'}

global TESTBED

if nargin>0 & ~isempty(reportType) & strcmpi(reportType,'all') reportType={'anchors', 'ranging', 'rangingValues', 'location'}; end
if nargin<2 | isempty(addr) addr='all'; end

if ~isfield(TESTBED,'reportTimer') | isempty(TESTBED.reportTimer)
    TESTBED.reportTimer=timer;
end
if nargin>=1 %the user is calling me
    stop(TESTBED.reportTimer)%in case it was running
    set(TESTBED.reportTimer, 'Name','Report Timer','TimerFcn', 'getReport', 'StartDelay', 1, 'Period', 1, 'ExecutionMode', 'fixedRate');

    if ischar(reportType)
      TESTBED.reportType={reportType};
    else
      TESTBED.reportType=reportType;
    end

    deads = vectorFind(TESTBED.deadNodes,TESTBED.nodeIDs);
    for i=1:length(TESTBED.reportType)
      switch(TESTBED.reportType{i}) %always use the next most interesting query
       case 'ident'
	TESTBED.identReported=zeros(size(TESTBED.identReported));
	TESTBED.identReported(deads)=1;
       case 'service'
	TESTBED.serviceReported=zeros(size(TESTBED.serviceReported));
	TESTBED.serviceReported(deads)=1;
       case 'anchors'
	TESTBED.anchorsReported=zeros(size(TESTBED.anchorsReported));
	TESTBED.anchorsReported(deads)=1;
       case 'ranging'
	TESTBED.rangingReported=zeros(size(TESTBED.rangingReported));
	TESTBED.rangingReported(deads)=1;
       case 'rangingValues'
	TESTBED.rangingValuesReported=zeros(size(TESTBED.rangingValuesReported));
	TESTBED.rangingValuesReported(deads)=1;
       case 'location'
	TESTBED.locationReported=zeros(size(TESTBED.locationReported));
	TESTBED.locationReported(deads)=1;
      end
    end
    
    start(TESTBED.reportTimer)
else %I want to send a query of a certain type
    switch(TESTBED.reportType{1}) %always use the next most interesting query
        case 'ident'
            array=TESTBED.identReported;
            command='ident';
        case 'service'
            array=TESTBED.serviceReported;
            command='service';
        case 'anchors'
            array=TESTBED.anchorsReported;
            command='CalamariReportAnchors';
        case 'ranging'
            array=TESTBED.rangingReported;
            command='CalamariReportRanging';
        case 'rangingValues'
            array=TESTBED.rangingValuesReported;
            command='CalamariReportRangingValues';
        case 'location'
            array=TESTBED.locationReported;
            command='LocationInfo';
    end
    if all(array) 
        disp(['GOT ALL REPORTS: ' TESTBED.reportType{1}])
        if length(TESTBED.reportType)==1 %I'm done
            stop(TESTBED.reportTimer)
        end
        TESTBED.reportType={TESTBED.reportType{min(end,2):end}};
    else
        index=find(array==0); %try to get as many as possible at first
	if length(index)>=length(array)*1
            disp(['peg all ' command])
            eval(['peg all ' command])
	    TESTBED.reportNode = 0;
	    TESTBED.reportTries = 0;
        else %then just focus on the ones that are not responding
	     %this is just for rangingvalues
	     if strcmpi(command,'CalamariReportRangingValues') 
	       if index(1)==TESTBED.reportNode 
		 TESTBED.reportTries = TESTBED.reportTries+1; 
	       else
		 TESTBED.reportNode = index(1);
		 TESTBED.reportTries=0;
	       end
	       if TESTBED.reportTries > 6 TESTBED.rangingValuesReported(index(1))=1;   end
	     end
	  if get(TESTBED.reportTimer,'period')>.3
	    stop(TESTBED.reportTimer)
	    set(TESTBED.reportTimer,'period',.3)
	    start(TESTBED.reportTimer)
	  end
	  disp(['          peg ' num2str(TESTBED.nodeIDs(index(1))) ' ' command])
	  eval(['peg ' num2str(TESTBED.nodeIDs(index(1))) ' ' command])
        end

	s=sprintf(' %16s : ', 'id');
	for i=1:length(TESTBED.nodeIDs)
	  s=[s sprintf(' %2d ',TESTBED.nodeIDs(i))];
	end
%	s=[s sprintf('\n')];
%	disp(s)
	
	s=sprintf(' %16s : ', command);
	for i=1:length(TESTBED.nodeIDs)
	  s=[s sprintf(' %2d ',array(i))];
	end
	s=[s sprintf('\n')];
%	disp(s)
	
    end
end
