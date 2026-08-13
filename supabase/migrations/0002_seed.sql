insert into priorities(name,sort_order) values ('Critical',1),('High',2),('Medium',3),('Low',4);
insert into request_types(name) values ('Enhancement'),('New System'),('New Module');
insert into reference_types(name) values ('GDocs'),('OneDrive'),('ELS'),('Jira');
insert into initiator_types(name) values ('System Owner'),('PMO'),('Developer'),('Higher Authority');
insert into workflow_template_stages(name,sort_order,detail_label,detail_required,detail_multiline) values
('Engagement Meeting',1,null,false,false),('TICRO #1 Requested',2,'Documents Submitted',true,true),('TICRO #1 Approved',3,null,false,false),('TICRO #2 Requested',4,'Documents Submitted',true,true),('TICRO #2 Approved',5,null,false,false),('Signed All Required Documents',6,null,false,false),('WBS Onboarded in Jira',7,null,false,false),('Dev Start',8,null,false,false),('Dev End',9,null,false,false),('UAT Start',10,null,false,false),('UAT End',11,null,false,false),('UAT Signed Off',12,null,false,false),('Deployed',13,'Deployment Version',true,false),('All Required Documents Submitted',14,null,false,false);

