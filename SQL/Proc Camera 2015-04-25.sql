USE [StoreLink]
GO
/****** Object:  StoredProcedure [dbo].[sp_User_Insert]    Script Date: 04/25/2015 11:12:36 ******/
DROP PROCEDURE [dbo].[sp_User_Insert]
GO
/****** Object:  StoredProcedure [dbo].[sp_User_Login]    Script Date: 04/25/2015 11:12:36 ******/
DROP PROCEDURE [dbo].[sp_User_Login]
GO
/****** Object:  StoredProcedure [dbo].[sp_User_ResetPassword]    Script Date: 04/25/2015 11:12:36 ******/
DROP PROCEDURE [dbo].[sp_User_ResetPassword]
GO
/****** Object:  StoredProcedure [dbo].[sp_User_Update]    Script Date: 04/25/2015 11:12:36 ******/
DROP PROCEDURE [dbo].[sp_User_Update]
GO
/****** Object:  StoredProcedure [dbo].[sp_User_UpdatePass]    Script Date: 04/25/2015 11:12:36 ******/
DROP PROCEDURE [dbo].[sp_User_UpdatePass]
GO
/****** Object:  StoredProcedure [dbo].[sp_UserLocation_ChangeCheckAll]    Script Date: 04/25/2015 11:12:36 ******/
DROP PROCEDURE [dbo].[sp_UserLocation_ChangeCheckAll]
GO
/****** Object:  StoredProcedure [dbo].[sp_UserLocation_Get]    Script Date: 04/25/2015 11:12:36 ******/
DROP PROCEDURE [dbo].[sp_UserLocation_Get]
GO
/****** Object:  StoredProcedure [dbo].[sp_UserLocation_GetCheckAll]    Script Date: 04/25/2015 11:12:36 ******/
DROP PROCEDURE [dbo].[sp_UserLocation_GetCheckAll]
GO
/****** Object:  StoredProcedure [dbo].[sp_UserLocation_GetPermission]    Script Date: 04/25/2015 11:12:36 ******/
DROP PROCEDURE [dbo].[sp_UserLocation_GetPermission]
GO
/****** Object:  StoredProcedure [dbo].[sp_UserLocation_SetValue]    Script Date: 04/25/2015 11:12:36 ******/
DROP PROCEDURE [dbo].[sp_UserLocation_SetValue]
GO
/****** Object:  StoredProcedure [dbo].[sp_Location_Insert]    Script Date: 04/25/2015 11:12:36 ******/
DROP PROCEDURE [dbo].[sp_Location_Insert]
GO
/****** Object:  StoredProcedure [dbo].[sp_Location_Update]    Script Date: 04/25/2015 11:12:36 ******/
DROP PROCEDURE [dbo].[sp_Location_Update]
GO
/****** Object:  StoredProcedure [dbo].[sp_User_Delete]    Script Date: 04/25/2015 11:12:36 ******/
DROP PROCEDURE [dbo].[sp_User_Delete]
GO
/****** Object:  StoredProcedure [dbo].[sp_Location_Delete]    Script Date: 04/25/2015 11:12:36 ******/
DROP PROCEDURE [dbo].[sp_Location_Delete]
GO
/****** Object:  StoredProcedure [dbo].[sp_Location_Get]    Script Date: 04/25/2015 11:12:36 ******/
DROP PROCEDURE [dbo].[sp_Location_Get]
GO
/****** Object:  StoredProcedure [dbo].[sp_User_GetAll]    Script Date: 04/25/2015 11:12:36 ******/
DROP PROCEDURE [dbo].[sp_User_GetAll]
GO
/****** Object:  StoredProcedure [dbo].[sp_User_GetAll]    Script Date: 04/25/2015 11:12:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Proc [dbo].[sp_User_GetAll]
@UserID int = -1,
@UserName varchar(50) = '',
@Authentication int = -1,
@UserType int = -1
As
Begin
	Declare @SQL nvarchar(2000) = ''
	SET @SQL = N'Select * from [User] Where 1 = 1'
	if(@UserID>-1)
		SET @SQL = @SQL + N' And UserID = ' + CAST(@UserID As varchar(9))	
	if(@UserName<>'')
		SET @SQL = @SQL + N' And UserName = ''' + @UserName	+''''
	if(@Authentication>-1)
		SET @SQL = @SQL + N' And Authentication = ' + CAST(@Authentication As varchar(1))
	if(@UserType>-1)
		SET @SQL = @SQL + N' And UserType = ' + CAST(@UserType As varchar(1))		
	--print @SQL
	EXECUTE sp_executesql @SQL
End
GO
/****** Object:  StoredProcedure [dbo].[sp_Location_Get]    Script Date: 04/25/2015 11:12:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[sp_Location_Get]
@LocationID int = -1,
@Search Nvarchar(255) = ''
As
Begin
	Declare @SQL nvarchar(500) = ''
	SET @SQL =  'Select * from Location Where 1 = 1'
	If(@LocationID > -1)
		SET @SQL = @SQL + ' And LocationID = ' + CAST(@LocationID As varchar(9))
	If(@Search<>'')
		SET @SQL = @SQL + ' And dbo.BoDau(Name) like ''%''+dbo.BoDau('''+@Search+''')+''%'''
	EXECUTE sp_executesql @SQL
End
GO
/****** Object:  StoredProcedure [dbo].[sp_Location_Delete]    Script Date: 04/25/2015 11:12:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
Create Proc [dbo].[sp_Location_Delete]
@LocationID int
As 
Begin
	Delete From UserLocation Where LocationID = @LocationID;
	Delete From Location Where LocationID = @LocationID;
End
GO
/****** Object:  StoredProcedure [dbo].[sp_User_Delete]    Script Date: 04/25/2015 11:12:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[sp_User_Delete]
@UserID int
As
Begin
	Delete From [User] Where UserID = @UserID
	Delete FROM UserLocation WHere UserID = @UserID
End
GO
/****** Object:  StoredProcedure [dbo].[sp_Location_Update]    Script Date: 04/25/2015 11:12:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Proc [dbo].[sp_Location_Update]
@LocationID int, 
@No varchar(50),
@Name Nvarchar(255),
@Link Nvarchar(255),
@UserName Nvarchar(50),
@Password nvarchar(15),
@CameraModel nvarchar(50),
@Status nvarchar(30),
@Description nvarchar(500)
As
Begin
Update Location Set 
	[No] = @No, 
	Name = @Name, 
	Link = @Link, 
	UserName = @UserName,
	[Password] = @Password,
	CameraModel  = @CameraModel,
	[Status] = @Status,
	[Description] = @Description 
	Where LocationID = @LocationID
End
GO
/****** Object:  StoredProcedure [dbo].[sp_Location_Insert]    Script Date: 04/25/2015 11:12:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Proc [dbo].[sp_Location_Insert]
@No varchar(50),
@Name Nvarchar(255),
@Link Nvarchar(255),
@UserName Nvarchar(50),
@Password nvarchar(15),
@CameraModel nvarchar(50),
@Status nvarchar(30),
@Description nvarchar(500)
As
Begin
	Insert Into Location([No], Name, Link, UserName, [Password], CameraModel, [Status], [Description])
	Values(@No, @Name, @Link, @UserName, @Password, @CameraModel,@Status, @Description)
End
GO
/****** Object:  StoredProcedure [dbo].[sp_UserLocation_SetValue]    Script Date: 04/25/2015 11:12:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[sp_UserLocation_SetValue]
@UserID int,
@LocationID int,
@Value bit
As
Begin
	If(@Value = 0)
		Delete From UserLocation Where LocationID = @LocationID And UserID = @UserID	
	Else
		If NOT Exists (Select * From UserLocation Where LocationID = @LocationID And UserID = @UserID)
		INSERT INTO UserLocation(UserID, LocationID) Values(@UserID, @LocationID)
	End
GO
/****** Object:  StoredProcedure [dbo].[sp_UserLocation_GetPermission]    Script Date: 04/25/2015 11:12:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[sp_UserLocation_GetPermission]
@UserID int
As
Begin
	Select L.LocationID, L.No, L.Name, L.Link, L.UserName, L.Password, L.CameraModel, L.Status, L.Description, ISNULL(TMP.LocationID, 0) As Value From
	(Select LocationID, ISNULL(LocationID, 0) As Value from UserLocation UL Inner Join [User] U ON U.UserID = UL.UserID Where U.UserID = @UserID)
	TMP
	RIGHT Join Location L ON L.LocationID = TMP.LocationID	
End
GO
/****** Object:  StoredProcedure [dbo].[sp_UserLocation_GetCheckAll]    Script Date: 04/25/2015 11:12:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[sp_UserLocation_GetCheckAll]
@UserID int
As
Begin
	DECLARE @count1 int = 0
	DECLARE @count2 int = 0
	Select @count1 = COUNT(*) From UserLocation Where UserID = @UserID
	Select @count2 = COUNT(*) From Location
	If(@count1 = @count2)
		Select CAST('1' as bit) Value
	else
		Select CAST('0' as bit) Value
	
End
GO
/****** Object:  StoredProcedure [dbo].[sp_UserLocation_Get]    Script Date: 04/25/2015 11:12:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[sp_UserLocation_Get]
@UserID int,
@Search Nvarchar(255) = ''
As
Begin
	Select UL.LocationID, L.[No], L.Name, L.Link, L.UserName,L.Password, L.CameraModel, L.Status, L.Description, ISNULL(UL.LocationID, 0) As Value 
	from UserLocation UL 
	Inner Join [User] U ON U.UserID = UL.UserID
	Inner Join Location L ON L.LocationID = UL.LocationID
	Where UL.UserID = @UserID And dbo.BoDau(Name) like '%'+dbo.BoDau(@Search)+'%'
End
GO
/****** Object:  StoredProcedure [dbo].[sp_UserLocation_ChangeCheckAll]    Script Date: 04/25/2015 11:12:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROC [dbo].[sp_UserLocation_ChangeCheckAll]
@UserID int,
@Value bit
As
Begin
	if(@Value = 1)
	Begin
		Delete From UserLocation Where UserID = @UserID
		Insert Into UserLocation Select @UserID as UserID, LocationID From Location
	End
	Else
		Delete From UserLocation Where UserID = @UserID
End
GO
/****** Object:  StoredProcedure [dbo].[sp_User_UpdatePass]    Script Date: 04/25/2015 11:12:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[sp_User_UpdatePass]
@UserID int,
@PasswordOld varchar(50),
@PasswordNew varchar(50)
As
Begin	
	Update [User] Set [Password] = CONVERT(NVARCHAR(32),HashBytes('MD5',@PasswordNew),2) Where UserID = @UserID And [Password] = CONVERT(NVARCHAR(32),HashBytes('MD5',@PasswordOld),2)
End
GO
/****** Object:  StoredProcedure [dbo].[sp_User_Update]    Script Date: 04/25/2015 11:12:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Proc [dbo].[sp_User_Update]
@UserID int,
@UserName varchar(50),
@Password varchar(50),
@FullName Nvarchar(50),
@UserType int = 0
As
Begin
	Update [User] SET	
	FullName = @FullName	
	Where UserID = @UserID	
End
GO
/****** Object:  StoredProcedure [dbo].[sp_User_ResetPassword]    Script Date: 04/25/2015 11:12:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[sp_User_ResetPassword]
@UserID int,
@Password varchar(50)
As
Begin	
	Update [User] Set [Password] = CONVERT(NVARCHAR(32),HashBytes('MD5',@Password),2) Where UserID = @UserID
End
GO
/****** Object:  StoredProcedure [dbo].[sp_User_Login]    Script Date: 04/25/2015 11:12:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE proc [dbo].[sp_User_Login]
@UserName nvarchar(50),
@Password varchar(50)
As
Begin
	Select Top 1 * From [User] Where UserName = @UserName And [Password] = CONVERT(NVARCHAR(32),HashBytes('MD5',@Password),2)
End
GO
/****** Object:  StoredProcedure [dbo].[sp_User_Insert]    Script Date: 04/25/2015 11:12:36 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE Proc [dbo].[sp_User_Insert]
@UserName varchar(50),
@Password varchar(50),
@FullName Nvarchar(50),
@Authentication int = 0,
@UserType int = 0
As
INSERT INTO [User] (UserName,[Password] , FullName, [Authentication], UserType)
Values(@UserName, CONVERT(NVARCHAR(32),HashBytes('MD5',@Password),2), @FullName, @Authentication, @UserType)
GO
